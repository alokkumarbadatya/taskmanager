//
//  ContentView.swift
//  taskmanager
//
//  Created by alok kumar badatya on 16/02/26.
//

import SwiftUI
import Combine

// MARK: - Task Model
struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var isCompleted: Bool
    var createdAt: Date
}

// MARK: - Task Manager (Data Layer)
class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    
    private let tasksKey = "savedTasks"
    
    init() {
        loadTasks()
    }
    
    // CREATE
    func addTask(title: String, description: String) {
        let newTask = Task(
            title: title,
            description: description,
            isCompleted: false,
            createdAt: Date()
        )
        tasks.append(newTask)
        saveTasks()
    }
    
    // READ
    func getTasks() -> [Task] {
        return tasks
    }
    
    // UPDATE
    func updateTask(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func toggleTaskCompletion(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    // DELETE
    func deleteTask(task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        saveTasks()
    }
    
    // Persistence
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var showingAddTask = false
    @State private var selectedTask: Task?
    
    var body: some View {
        NavigationView {
            ZStack {
                if taskManager.tasks.isEmpty {
                    EmptyStateView()
                } else {
                    TaskListView(
                        tasks: taskManager.tasks,
                        onToggle: { task in
                            taskManager.toggleTaskCompletion(task: task)
                        },
                        onDelete: { offsets in
                            taskManager.deleteTask(at: offsets)
                        },
                        onTap: { task in
                            selectedTask = task
                        }
                    )
                }
            }
            .navigationTitle("📝 My Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(taskManager: taskManager)
            }
            .sheet(item: $selectedTask) { task in
                EditTaskView(task: task, taskManager: taskManager)
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text("No Tasks Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to add your first task")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Task List View
struct TaskListView: View {
    let tasks: [Task]
    let onToggle: (Task) -> Void
    let onDelete: (IndexSet) -> Void
    let onTap: (Task) -> Void
    
    var body: some View {
        List {
            ForEach(tasks) { task in
                TaskRowView(task: task, onToggle: onToggle)
                    .onTapGesture {
                        onTap(task)
                    }
            }
            .onDelete(perform: onDelete)
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: Task
    let onToggle: (Task) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                onToggle(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Text(task.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var taskManager: TaskManager
    
    @State private var title = ""
    @State private var description = ""
    @FocusState private var titleFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                        .focused($titleFieldFocused)
                    
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text("Description (optional)")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                            },
                            alignment: .topLeading
                        )
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        taskManager.addTask(title: title, description: description)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                titleFieldFocused = true
            }
        }
    }
}

// MARK: - Edit Task View
struct EditTaskView: View {
    @Environment(\.dismiss) var dismiss
    let task: Task
    @ObservedObject var taskManager: TaskManager
    @State private var title = ""
    @State private var description = ""
    @State private var isCompleted = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section {
                    Toggle("Completed", isOn: $isCompleted)
                }
                
                Section {
                    Button(role: .destructive) {
                        taskManager.deleteTask(task: task)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Task")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedTask = task
                        updatedTask.title = title
                        updatedTask.description = description
                        updatedTask.isCompleted = isCompleted
                        taskManager.updateTask(task: updatedTask)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                title = task.title
                description = task.description
                isCompleted = task.isCompleted
            }
        }
    }
}

// Note: Remove or comment out your existing @main App struct in your project
// and uncomment this, OR just use ContentView() in your existing App struct
