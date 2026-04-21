import SwiftUI

struct ServerImportSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var address: String
    @State private var username: String
    @State private var password: String

    let onSave: (String, String, String) -> Void

    init(initialAddress: String, initialUsername: String, initialPassword: String, onSave: @escaping (String, String, String) -> Void) {
        _address = State(initialValue: initialAddress)
        _username = State(initialValue: initialUsername)
        _password = State(initialValue: initialPassword)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("服务器") {
                    TextField("地址，例如 https://example.com", text: $address)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("用户名", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("密码", text: $password)
                }
            }
            .navigationTitle("导入服务器")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("登录") {
                        onSave(
                            address.trimmingCharacters(in: .whitespacesAndNewlines),
                            username.trimmingCharacters(in: .whitespacesAndNewlines),
                            password.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        dismiss()
                    }
                    .disabled(
                        address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
    }
}
