import Testing
import Foundation
@testable import Agent_

@Suite("ShellSafetyService")
struct ShellSafetyServiceTests {

    // MARK: - Helpers

    private func blocked(_ command: String, context: ShellSafetyService.Context = .userAgent) -> Bool {
        !ShellSafetyService.check(command, context: context).allowed
    }

    private func rule(_ command: String, context: ShellSafetyService.Context = .userAgent) -> String? {
        ShellSafetyService.check(command, context: context).rule
    }

    // MARK: - Catastrophic rm (user agent)

    @Test("rm -rf / is blocked")
    func rmRootBlocked() {
        #expect(blocked("rm -rf /"))
        #expect(rule("rm -rf /") == "rm.dangerous-target")
    }

    @Test("rm -rf / flag variants are blocked")
    func rmRootFlagVariants() {
        #expect(blocked("rm -Rf /"))
        #expect(blocked("rm -fR /"))
        #expect(blocked("rm -fr /"))
        #expect(blocked("rm -r -f /"))
        #expect(blocked("rm --recursive --force /"))
    }

    @Test("rm --no-preserve-root is always blocked")
    func noPreserveRoot() {
        #expect(blocked("rm -rf --no-preserve-root /"))
        #expect(rule("rm -rf --no-preserve-root /") == "rm.no-preserve-root")
        #expect(blocked("rm --no-preserve-root -rf /tmp/x"))
    }

    @Test("rm -rf home directory forms are blocked")
    func rmHomeBlocked() {
        #expect(blocked("rm -rf ~"))
        #expect(blocked("rm -rf ~/"))
        #expect(blocked("rm -rf ~/*"))
        #expect(blocked("rm -rf $HOME"))
        #expect(blocked("rm -rf ${HOME}"))
        #expect(blocked("rm -rf $HOME/*"))
        #expect(blocked("rm -rf \(NSHomeDirectory())"))
    }

    @Test("rm -rf bare globs and relative dirs are blocked")
    func rmGlobsBlocked() {
        #expect(blocked("rm -rf *"))
        #expect(blocked("rm -rf ."))
        #expect(blocked("rm -rf .."))
        #expect(blocked("rm -rf .*"))
        #expect(blocked("rm -rf ./*"))
    }

    @Test("rm -rf system roots are blocked for user agent")
    func rmSystemRootsBlocked() {
        #expect(blocked("rm -rf /etc"))
        #expect(blocked("rm -rf /usr"))
        #expect(blocked("rm -rf /System"))
        #expect(blocked("rm -rf /Library"))
        #expect(blocked("rm -rf /Users"))
        #expect(blocked("rm -rf /var/"))
        #expect(blocked("rm -rf /Applications/*"))
    }

    @Test("rm -rf on a specific subdirectory is allowed")
    func rmSpecificPathAllowed() {
        #expect(!blocked("rm -rf /tmp/build"))
        #expect(!blocked("rm -rf ~/Documents/scratch"))
        #expect(!blocked("rm -rf ./node_modules"))
        #expect(!blocked("rm -rf /Users/toddbruss/Documents/old-project"))
    }

    @Test("rm without both -r and -f is allowed")
    func rmWithoutBothFlags() {
        #expect(!blocked("rm -r /tmp/x"))
        #expect(!blocked("rm -f file.txt"))
        #expect(!blocked("rm file.txt"))
    }

    // MARK: - Prefix wrappers & compound commands

    @Test("sudo/exec/eval wrappers cannot disguise rm -rf /")
    func wrappersStripped() {
        #expect(blocked("sudo rm -rf /"))
        #expect(blocked("exec rm -rf /"))
        #expect(blocked("sudo exec sudo rm -rf /"))
        #expect(blocked("eval rm -rf /"))
        #expect(blocked("doas rm -rf /"))
        #expect(blocked("command rm -rf /"))
    }

    @Test("env-var prefix cannot disguise rm -rf /")
    func envVarPrefixStripped() {
        #expect(blocked("FOO=bar rm -rf /"))
        #expect(blocked("A=1 B=2 rm -rf ~"))
    }

    @Test("dangerous segment in compound command is blocked")
    func compoundCommands() {
        #expect(blocked("ls; rm -rf /"))
        #expect(blocked("echo hi && rm -rf ~"))
        #expect(blocked("true || rm -rf /etc"))
        #expect(blocked("echo x | rm -rf *"))
        #expect(blocked("ls\nrm -rf /"))
    }

    @Test("harmless compound commands are allowed")
    func harmlessCompound() {
        #expect(!blocked("cd /tmp && ls -la"))
        #expect(!blocked("git status; git log --oneline"))
        #expect(!blocked("echo 'rm -rf /' is a string"))
    }

    // MARK: - find -delete

    @Test("find -delete with broad root is blocked")
    func findDeleteBroad() {
        #expect(blocked("find / -name '*.log' -delete"))
        #expect(blocked("find ~ -delete"))
        #expect(blocked("find /etc -name x -delete"))
        #expect(rule("find / -delete") == "find.delete-broad-root")
    }

    @Test("find -delete with narrow root is allowed")
    func findDeleteNarrow() {
        #expect(!blocked("find /tmp/build -name '*.o' -delete"))
        #expect(!blocked("find ~/Documents/logs -name '*.log' -delete"))
    }

    @Test("find without -delete is allowed anywhere")
    func findWithoutDelete() {
        #expect(!blocked("find / -name 'foo.txt'"))
        #expect(!blocked("find ~ -type d"))
    }

    // MARK: - chmod/chown -R

    @Test("recursive chmod/chown on system roots is blocked")
    func recursivePermsBlocked() {
        #expect(blocked("chmod -R 777 /"))
        #expect(blocked("chown -R nobody /etc"))
        #expect(blocked("chmod -R 000 ~"))
        #expect(rule("chmod -R 777 /") == "perms.recursive-on-root")
    }

    @Test("recursive chmod/chown on narrow paths is allowed")
    func recursivePermsNarrowAllowed() {
        #expect(!blocked("chmod -R 755 /tmp/mydir"))
        #expect(!blocked("chown -R todd ~/Documents/project"))
        #expect(!blocked("chmod 644 /etc/hosts"))
    }

    // MARK: - Fork bomb

    @Test("classic fork bomb is blocked")
    func forkBomb() {
        #expect(blocked(":(){ :|:& };:"))
        #expect(blocked(":(){:|:&};:"))
        #expect(rule(":(){ :|:& };:") == "fork-bomb")
    }

    // MARK: - mv to /dev/null

    @Test("mv home or system dir to /dev/null is blocked")
    func mvToDevNull() {
        #expect(blocked("mv ~ /dev/null"))
        #expect(blocked("mv /etc /dev/null"))
        #expect(rule("mv ~ /dev/null") == "mv.to-devnull")
    }

    @Test("mv of normal files is allowed")
    func mvNormalAllowed() {
        #expect(!blocked("mv a.txt b.txt"))
        #expect(!blocked("mv /tmp/x /tmp/y"))
        #expect(!blocked("mv output.log /dev/null"))
    }

    // MARK: - Root daemon context

    @Test("root daemon still blocks the three catastrophic rm patterns")
    func rootDaemonCatastrophicBlocked() {
        #expect(blocked("rm -rf /", context: .rootDaemon))
        #expect(blocked("rm -rf *", context: .rootDaemon))
        #expect(blocked("rm -rf ~", context: .rootDaemon))
        #expect(blocked("rm -rf $HOME", context: .rootDaemon))
        #expect(blocked("rm -rf --no-preserve-root /", context: .rootDaemon))
        #expect(rule("rm -rf /", context: .rootDaemon) == "rm.catastrophic")
    }

    @Test("root daemon allows system-admin operations")
    func rootDaemonAllowsAdminOps() {
        #expect(!blocked("rm -rf /etc/old-config", context: .rootDaemon))
        #expect(!blocked("rm -rf /usr", context: .rootDaemon))
        #expect(!blocked("find / -name x -delete", context: .rootDaemon))
        #expect(!blocked("chmod -R 755 /opt/tool", context: .rootDaemon))
        #expect(!blocked("diskutil eraseDisk JHFS+ Backup /dev/disk5", context: .rootDaemon))
        #expect(!blocked("dd if=/tmp/img of=/dev/disk5 bs=4M", context: .rootDaemon))
    }

    @Test("root daemon blocks catastrophic rm inside compound command")
    func rootDaemonCompound() {
        #expect(blocked("ls; rm -rf /", context: .rootDaemon))
        #expect(!blocked("cd /tmp && ls", context: .rootDaemon))
    }

    // MARK: - Everyday commands stay allowed

    @Test("everyday commands are allowed")
    func everydayAllowed() {
        #expect(!blocked("ls -la"))
        #expect(!blocked("git commit -m 'rm -rf / in a message'"))
        #expect(!blocked("swift build"))
        #expect(!blocked("xcodebuild -project Agent.xcodeproj"))
        #expect(!blocked("grep -r 'pattern' ."))
        #expect(!blocked("cat /etc/hosts"))
        #expect(!blocked("brew install wget"))
        #expect(!blocked(""))
        #expect(!blocked("   "))
    }

    @Test("quoted dangerous strings are not false positives")
    func quotedStringsNotBlocked() {
        #expect(!blocked("echo \"rm -rf /\""))
        #expect(!blocked("printf 'never run rm -rf ~'"))
    }

    @Test("verdict block carries reason and rule")
    func verdictShape() {
        let v = ShellSafetyService.check("rm -rf /")
        #expect(!v.allowed)
        #expect(v.reason != nil)
        #expect(v.rule != nil)
        let ok = ShellSafetyService.check("ls")
        #expect(ok.allowed)
        #expect(ok.reason == nil)
        #expect(ok.rule == nil)
    }
}
