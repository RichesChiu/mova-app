//
//  ContentView.swift
//  Mova
//
//  Created by Riches Chiu on 2026/4/20.
//

import SwiftUI

struct AppRootView: View {
    @StateObject private var viewModel = AppRootViewModel()

    @State private var showServerImportSheet = false
    @State private var pendingDeletion: SourceType?

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.hasValidatedServer {
                    HomeView(
                        libraries: viewModel.libraries,
                        libraryPreviewItems: viewModel.libraryPreviewItems,
                        libraryItemsByID: viewModel.libraryItemsByID,
                        libraryStatsByID: viewModel.libraryStatsByID,
                        selectedLibraryID: viewModel.selectedLibraryID,
                        mediaItems: viewModel.mediaItems,
                        isLoading: viewModel.isHomeLoading,
                        imageRequest: viewModel.imageRequest(for:),
                        loadMediaDetail: viewModel.loadMediaDetail(for:),
                        loadEpisodeOutline: viewModel.loadEpisodeOutline(for:),
                        loadCastMembers: viewModel.loadCastMembers(for:),
                        loadMediaFiles: viewModel.loadMediaFiles(for:),
                        loadAudioTracks: viewModel.loadAudioTracks(for:),
                        loadSubtitles: viewModel.loadSubtitles(for:),
                        onImport: { showServerImportSheet = true },
                        onDeleteServer: { pendingDeletion = .server },
                        onReload: {
                            Task {
                                await viewModel.loadHomeData()
                            }
                        },
                        onSelectLibrary: { id in
                            Task {
                                await viewModel.selectLibrary(id)
                            }
                        }
                    )
                } else {
                    SourceSetupView(
                        hasAnySource: viewModel.hasAnySource,
                        hasServerInfo: viewModel.hasServerInfo,
                        hasValidatedServer: viewModel.hasValidatedServer,
                        serverAddress: viewModel.serverAddress,
                        onImport: { showServerImportSheet = true },
                        onDeleteServer: { pendingDeletion = .server }
                    )
                }

                if viewModel.isLoading {
                    checkingOverlay
                }
            }
        }
        .task {
            await viewModel.restoreSessionIfNeeded()
            if viewModel.hasValidatedServer {
                await viewModel.loadHomeData()
            }
        }
        .sheet(isPresented: $showServerImportSheet) {
            ServerImportSheet(
                initialAddress: viewModel.serverAddress,
                initialUsername: viewModel.serverUsername,
                initialPassword: ""
            ) { address, username, password in
                Task {
                    await viewModel.loginWithServer(address: address, username: username, password: password)
                }
            }
        }
        .alert("提示", isPresented: showAlertBinding) {
            Button("确定", role: .cancel) {
                viewModel.clearAlert()
            }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .confirmationDialog("确认删除", isPresented: showDeleteConfirmation, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                guard let source = pendingDeletion else { return }
                performDeletion(for: source)
                pendingDeletion = nil
            }
            Button("取消", role: .cancel) {
                pendingDeletion = nil
            }
        } message: {
            if let source = pendingDeletion {
                Text("将删除\(source.title)信息，删除后需要重新导入。")
            }
        }
    }

    private var showDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { newValue in
                if !newValue {
                    pendingDeletion = nil
                }
            }
        )
    }

    private var showAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.clearAlert()
                }
            }
        )
    }

    private var checkingOverlay: some View {
        Color.black.opacity(0.2)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("正在登录并获取 token...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
    }

    private func performDeletion(for source: SourceType) {
        switch source {
        case .server:
            viewModel.deleteServer()
        }
    }
}

#Preview {
    AppRootView()
}
