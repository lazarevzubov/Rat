@MainActor
func waitFor(_ timeout: Duration = .seconds(5), until condition: () async -> Bool) async {
    let deadline = ContinuousClock.now + timeout
    while !(await condition()),
          ContinuousClock.now < deadline {
        try? await Task.sleep(for: .milliseconds(5))
    }
}
