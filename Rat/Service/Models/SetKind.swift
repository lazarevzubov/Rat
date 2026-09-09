/// Distinguishes a warm-up set from a working set within a set template.
enum SetKind: String, Codable {

    /// A warm-up set, entered as a free weight rather than a percentage of max.
    case warmUp
    /// A working set, entered as a percentage of the exercise's max.
    case working

}
