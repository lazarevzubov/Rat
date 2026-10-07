import SwiftUI

/// Lists all persisted programs, and offers creating, editing, and deleting them.
struct ProgramListView: View {

    // MARK: - Properties

    // MARK: View protocol properties

    var body: some View {
        List {
            ForEach(viewModel.programs) { program in
                NavigationLink(program.name) {
                    ProgramEditorView(viewModel: viewModel.makeProgramEditorViewModel(program: program))
                }
            }
                .onDelete { viewModel.handleDelete(at: $0) }
        }
            .navigationTitle("Programs")
            .onChange(of: viewModel.programs.isEmpty) {
                if $1 {
                    editMode = .inactive
                }
            }
            .toolbar {
                if !viewModel.programs.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                            .accessibilityLabel("Reorder or Delete Programs")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Program", systemImage: "plus") { viewModel.handleAddProgramButtonTap() }
                }
            }
            .sheet(item: $viewModel.newProgram) { program in
                NavigationStack {
                    ProgramEditorView(viewModel: viewModel.makeProgramEditorViewModel(program: program))
                }
            }
            .task { await viewModel.handleAppear() }
            .alert("Couldn't load programs", isPresented: errorBinding) {
                // No custom actions—the default "OK" button just dismisses the alert.
            } message: {
                Text(viewModel.loadError?.localizedDescription ?? "")
            }
            .environment(\.editMode, $editMode)
    }

    // MARK: Private properties

    @State
    private var editMode = EditMode.inactive
    private var errorBinding: Binding<Bool> {
        Binding { viewModel.loadError != nil } set: {
            if !$0 {
                viewModel.dismissLoadError()
            }
        }
    }
    @State
    private var viewModel: ProgramListViewModel

    // MARK: - Initialization

    /// Creates a program list view.
    /// - Parameter viewModel: The view model backing this view.
    init(viewModel: ProgramListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

}

// MARK: -

#if DEBUG
#Preview {
    NavigationStack {
        ProgramListView(viewModel: PreviewSupport.makeProgramListViewModel())
    }
}
#endif
