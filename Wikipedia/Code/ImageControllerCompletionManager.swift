import Foundation

internal struct ImageControllerPermanentCacheCompletion {
    let success: () -> Void
    let failure: (Error) -> Void
}

internal struct ImageControllerDataCompletion {
    let success: (Data, URLResponse) -> Void
    let failure: (Error) -> Void
}

internal class ImageControllerCompletionManager<T> {
    var completions: [String: [String: T]] = [:]
    var tasks: [String: [String:URLSessionTask]] = [:]
    let queue = DispatchQueue(label: "ImageControllerCompletionManager-" + UUID().uuidString)
    
    func add(_ completion: T, priority: Float, forGroup group: String, identifier: String, token: String) -> Bool {
        return queue.sync {
            var completionsForKey = completions[identifier] ?? [:]
            let isFirst = completionsForKey.count == 0
            if !isFirst {
                self.tasks[group]?[identifier]?.priority = priority
            }
            completionsForKey[token] = completion
            completions[identifier] = completionsForKey
            return isFirst
        }
    }
    
    func add(_ completion: T, priority: Float, forIdentifier identifier: String, token: String) -> Bool {
        return add(completion, priority: priority, forGroup: "", identifier: identifier, token: token)
    }
    
    func add(_ task: URLSessionTask, forGroup group: String, identifier: String) {
        queue.sync {
            var groupTasks = tasks[group] ?? [:]
            groupTasks[identifier] = task
            tasks[group] = groupTasks
        }
    }
    
    func add(_ task: URLSessionTask, forIdentifier identifier: String) {
        add(task, forGroup: "", identifier: identifier)
    }
    
    
    func cancel(group: String, identifier: String, token: String) {
        queue.async {
            guard var tasks = self.tasks[group], let task = tasks[identifier], var completions = self.completions[identifier] else {
                return
            }
            completions.removeValue(forKey: token)
            if completions.count == 0 {
                self.completions.removeValue(forKey: identifier)
                task.cancel()
                tasks.removeValue(forKey: identifier)
                self.tasks[group] = tasks
            } else {
                self.completions[identifier] = completions
            }
        }
    }
    
    func cancel(group: String, identifier: String) {
        queue.async {
            guard var tasks = self.tasks[group], let task = tasks[identifier] else {
                return
            }
            self.completions.removeValue(forKey: identifier)
            task.cancel()
            tasks.removeValue(forKey: identifier)
            self.tasks[group] = tasks
        }
    }
    
    func cancel(_ identifier: String) {
        cancel(group: "", identifier: identifier)
    }
    
    func cancel(_ identifier: String, token: String) {
        cancel(group: "", identifier: identifier, token: token)
    }
    
    func cancel(group: String) {
        queue.async {
            guard let tasks = self.tasks[group] else {
                return
            }
            for (identifier, task) in tasks {
                self.completions.removeValue(forKey: identifier)
                task.cancel()
            }
        }
    }
    
    func complete(_ group: String, identifier: String, enumerator: @escaping (T) -> Void) {
        queue.async {
            guard let completionsForKey = self.completions[identifier] else {
                return
            }
            for (_, completion) in completionsForKey {
                enumerator(completion)
            }
            self.completions.removeValue(forKey: identifier)
            self.tasks[group]?.removeValue(forKey: identifier)
        }
    }
    
    func complete(_ identifier: String, enumerator: @escaping (T) -> Void) {
        complete("", identifier: identifier, enumerator: enumerator)
    }
}
