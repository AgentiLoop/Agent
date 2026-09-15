import Foundation

/// Kill a spawned shell/runner AND every descendant it forked. `Process.terminate()`
/// only signals the direct child; its children reparent to launchd and keep running
/// (as root, in the helper's case). Shared by the app (in-process TCC shells, agent
/// script runner) and both launchd daemons.
enum ProcessTree {
    /// SIGTERM the whole tree, then SIGKILL anything still alive after `grace` seconds.
    static func kill(rootPID: pid_t, grace: TimeInterval = 2.0) {
        var pids = descendants(of: rootPID)
        pids.append(rootPID)
        for pid in pids { Darwin.kill(pid, SIGTERM) }
        DispatchQueue.global().asyncAfter(deadline: .now() + grace) {
            // Re-walk: anything that spawned after the first pass is caught too.
            var survivors = descendants(of: rootPID)
            survivors.append(rootPID)
            for pid in survivors where Darwin.kill(pid, 0) == 0 {
                Darwin.kill(pid, SIGKILL)
            }
        }
    }

    /// All transitive children of `pid`, deepest first (so leaves die before their parents).
    static func descendants(of pid: pid_t) -> [pid_t] {
        let parents = parentMap()
        var childrenOf: [pid_t: [pid_t]] = [:]
        for (child, parent) in parents { childrenOf[parent, default: []].append(child) }
        var result: [pid_t] = []
        var queue: [pid_t] = childrenOf[pid] ?? []
        while !queue.isEmpty {
            let p = queue.removeFirst()
            result.append(p)
            queue.append(contentsOf: childrenOf[p] ?? [])
        }
        return result.reversed()
    }

    /// pid → ppid for every process on the system (sysctl KERN_PROC_ALL).
    private static func parentMap() -> [pid_t: pid_t] {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &size, nil, 0) == 0, size > 0 else { return [:] }
        let stride = MemoryLayout<kinfo_proc>.stride
        var procs = [kinfo_proc](repeating: kinfo_proc(), count: size / stride + 32)
        size = procs.count * stride
        guard sysctl(&mib, UInt32(mib.count), &procs, &size, nil, 0) == 0 else { return [:] }
        var map: [pid_t: pid_t] = [:]
        for p in procs.prefix(size / stride) {
            map[p.kp_proc.p_pid] = p.kp_eproc.e_ppid
        }
        return map
    }
}
