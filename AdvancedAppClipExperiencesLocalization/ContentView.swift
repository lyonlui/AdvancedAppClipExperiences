//
//  ContentView.swift
//  AdvancedAppClipExperiencesLocalization
//
//  Created by zhiwei liu on 2024/12/16.
//

import SwiftUI
import AppStoreConnect_Swift_SDK

struct ContentView: View {
    @ObservedObject var viewModel = AppsListViewModel()
    var body: some View {
        NavigationView {
            ZStack {
                List(viewModel.apps) { app in
                    VStack(alignment: .leading) {
                        Text(app.attributes?.name ?? "Unknown name")
                            .font(.headline)
                        Text(app.attributes?.bundleID ?? "Unknown bundle ID")
                            .font(.subheadline)
                        Text(app.id)
                            .font(.subheadline)
                    }
                }
                ProgressView()
                    .opacity(viewModel.apps.isEmpty ? 1.0 : 0.0)
            }.navigationTitle("List of Apps")
                .toolbar {
                    ToolbarItemGroup(placement: .automatic) {
                        Button("Refresh") {
                            viewModel.loadApps()
                        }

                        Button("Fail") {
                            viewModel.loadFailureExample()
                        }
                    }
                }
        }.onAppear {
            viewModel.loadApps()
        }
        
        
    }
}

final class AppsListViewModel: ObservableObject {
    @Published var apps: [AppStoreConnect_Swift_SDK.App] = []
    @Published var appclips: [AppStoreConnect_Swift_SDK.AppClip] = []
    @Published var appclipadvenexpers: [AppStoreConnect_Swift_SDK.AppClipAdvancedExperience] = []
    
    
    //1. set up your appstoreconnect api key
    //1. 设置你的appstoreconnect api相关信息
    
    /// Go to https://appstoreconnect.apple.com/access/api and create your own key. This is also the page to find the private key ID and the issuer ID.
    /// Download the private key and open it in a text editor. Remove the enters and copy the contents over to the private key parameter.
    private let configuration = try! APIConfiguration(issuerID: "<YOUR ISSUER ID>", privateKeyID: "<YOUR PRIVATE KEY ID>", privateKey: "<YOUR PRIVATE KEY>")

    private lazy var provider: APIProvider = APIProvider(configuration: configuration)
    
    
    //2. get you app id
    //2. 获取你应用的id
    func loadApps() {
        Task.detached {
            let request = APIEndpoint
                .v1
                .apps
                .get(parameters: .init(
                    sort: [.bundleID],
                    fieldsApps: [.appInfos, .name, .bundleID],
                    limit: 5
                ))

            do {
                let apps = try await self.provider.request(request).data
                await self.updateApps(to: apps)
            } catch {
                print("Something went wrong fetching the apps: \(error.localizedDescription)")
            }
        }
    }
    
    
    //3. Read App Clip Information(The opaque resource ID that uniquely identifies the App Clips resource.)
    //3. 获取轻应用信息(轻应用唯一ID)
    func loadAppclipsInfo() {
        Task.detached {
            let request = APIEndpoint
                .v1
                .apps
                .id("<app id>")
                .appClips
                .get(parameters: .init())

            do {
                let appclips = try await self.provider.request(request).data
                await self.updateAppClips(to: appclips)
            } catch {
                print("Something went wrong fetching the apps: \(error.localizedDescription)")
            }
        }
    }
    
    //4. List All Advanced App Clip Experiences for an App Clip(The opaque resource ID that uniquely identifies the Advanced App Clip Experiences resource.)
    //4. 列出所有高级轻应用体验(高级轻应用体验的ID)
    func LoadAllAdvancedAppClipExperiences() {
        Task.detached {
            let request = APIEndpoint
                .v1
                .appClips
                .id("<appclip id>")
                .appClipAdvancedExperiences
                .get(parameters: .init())

            do {
                let appclipadvenexpers = try await self.provider.request(request).data
                await self.updateAdvancedAppClipsExperiences(to: appclipadvenexpers)
            } catch {
                print("Something went wrong fetching the apps: \(error.localizedDescription)")
            }
        }
    }
    
    
    //5. Read Advanced App Clip Experience Information
    //5. 读取轻应用高级体验信息
    func ReadAdvancedAppClipExperienceInfo() {
        Task.detached {
            print("task start")
            let request = APIEndpoint
                .v1
                .appClipAdvancedExperiences
                .id("<Advanced App Clip Experience id>")
                .get(parameters: .init(fieldsAppClipAdvancedExperiences: [.appClip, .localizations], include: [.appClip, .localizations]))
            
            
            do {
                let resp = try await self.provider.request(request)
                print(resp.data)
                print(resp.included ?? "null")
                
                if let items = resp.included {
                    for item in items{
                        switch(item){
                        case .appClipAdvancedExperienceLocalization(let location):
                            print(location.id)
                            print(location.attributes?.language)
                            print(location.attributes?.title)
                            print(location.attributes?.subtitle)
                        default:
                            print(item)
                            
                        }
                        
                    }
                }
            } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
                print("Request failed with statuscode: \(statusCode) and the following errors:")
                errorResponse?.errors?.forEach({ error in
                    print("Error code: \(error.code)")
                    print("Error title: \(error.title)")
                    print("Error detail: \(error.detail)")
                })
            } catch {
                print("Something went wrong fetching the apps: \(error.localizedDescription)")
            }
        }
    }
    
    
    //6. Update Advanced App Clip Experience Information
    //6. 更新轻应用高级体验信息
    func UpdateAdvancedAppClipExperienceInfo() {
        Task.detached {
            print("task start")
            let request = APIEndpoint
                .v1
                .appClipAdvancedExperiences
                .id("<Advanced App Clip Experience id>")
                .patch(.init(data: AppClipAdvancedExperienceUpdateRequest.Data(
                    type: .appClipAdvancedExperiences,
                    id: "<Advanced App Clip Experience id>",
                    attributes: nil, // 不需要更新其他主要属性
                    relationships: .init(localizations: .init(data: [
                        .init(type: .appClipAdvancedExperienceLocalizations, id: "EN"),
                        .init(type: .appClipAdvancedExperienceLocalizations, id: "ZH")
                    ]))
                ), included: [
                    AppClipAdvancedExperienceLocalizationInlineCreate(
                        type: .appClipAdvancedExperienceLocalizations,
                        id: "EN",
                        attributes: AppClipAdvancedExperienceLocalizationInlineCreate.Attributes(
                            language: .en,
                            title: "Click Open button to operate",
                            subtitle: "Hello World!"
                        )),
                    AppClipAdvancedExperienceLocalizationInlineCreate(
                        type: .appClipAdvancedExperienceLocalizations,
                        id: "ZH",
                        attributes: AppClipAdvancedExperienceLocalizationInlineCreate.Attributes(
                            language: .zh,
                            title: "点击打开按钮操作",
                            subtitle: "您好！"
                        ))
                    
                ]))
            
            
            do {
                let resp = try await self.provider.request(request)
                print(resp.data)
                print(resp.included ?? "null")
            } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
                print("Request failed with statuscode: \(statusCode) and the following errors:")
                errorResponse?.errors?.forEach({ error in
                    print("Error code: \(error.code)")
                    print("Error title: \(error.title)")
                    print("Error detail: \(error.detail)")
                })
            } catch {
                print("Something went wrong fetching the apps: \(error.localizedDescription)")
            }
        }
    }
    

    /// This demonstrates a failing example and how you can catch error details.
    func loadFailureExample() {
        Task.detached {
            let requestWithError = APIEndpoint
                .v1
                .builds
                .id("app.appId")
                .get()

            do {
                print(try await self.provider.request(requestWithError).data)
            } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
                print("Request failed with statuscode: \(statusCode) and the following errors:")
                errorResponse?.errors?.forEach({ error in
                    print("Error code: \(error.code)")
                    print("Error title: \(error.title)")
                    print("Error detail: \(error.detail)")
                })
            } catch {
                print("Something went wrong fetching the apps: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func updateApps(to apps: [AppStoreConnect_Swift_SDK.App]) {
        self.apps = apps
        for app in apps {
            print("app id :\(app.id)")
        }
    }
    
    @MainActor
    private func updateAppClips(to apps: [AppStoreConnect_Swift_SDK.AppClip]) {
        self.appclips = apps
        for appclip in appclips {
            print("appclip id :\(appclip.id)")
        }
    }
    
    @MainActor
    private func updateAdvancedAppClipsExperiences(to appclipadvenexpers: [AppStoreConnect_Swift_SDK.AppClipAdvancedExperience]) {
        self.appclipadvenexpers = appclipadvenexpers
        for appclipadvenexper in appclipadvenexpers {
            print("Advanced App Clips Experiences id :\(appclipadvenexper.id)")
        }
    }
    
    
}

#Preview {
    ContentView()
}
