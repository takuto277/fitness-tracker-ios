import SwiftUI

struct ExerciseSetupView: View {
    let exercise: ExerciseType
    @Binding var isPresented: Bool
    let onStart: (ExerciseType, Int, Int, Double) -> Void
    
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight = 20.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.05, blue: 0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // ヘッダー
                    headerSection
                    
                    // エクササイズ情報
                    exerciseInfoSection
                    
                    // 設定項目
                    settingsSection
                    
                    Spacer()
                    
                    // 開始ボタン
                    startButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text("エクササイズ設定")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // プレースホルダー
                Color.clear
                    .frame(width: 24, height: 24)
            }
        }
    }
    
    // MARK: - Exercise Info Section
    private var exerciseInfoSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.cyan.opacity(0.8), .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: exercise.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(exercise.displayName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.cyan)
        }
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 25) {
            // セット数
            VStack(alignment: .leading, spacing: 10) {
                Text("セット数")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack {
                    Button(action: {
                        if sets > 1 { sets -= 1 }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.cyan)
                    }
                    
                    Spacer()
                    
                    Text("\(sets)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(minWidth: 60)
                    
                    Spacer()
                    
                    Button(action: {
                        if sets < 10 { sets += 1 }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.cyan)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // 回数
            VStack(alignment: .leading, spacing: 10) {
                Text("回数")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack {
                    Button(action: {
                        if reps > 1 { reps -= 1 }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.cyan)
                    }
                    
                    Spacer()
                    
                    Text("\(reps)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(minWidth: 60)
                    
                    Spacer()
                    
                    Button(action: {
                        if reps < 50 { reps += 1 }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.cyan)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // 重量（腹筋以外）
            if exercise != .abs {
                VStack(alignment: .leading, spacing: 10) {
                    Text("重量 (kg)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack {
                        Button(action: {
                            if weight > 1 { weight -= 1 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.cyan)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(weight))")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(minWidth: 60)
                        
                        Spacer()
                        
                        Button(action: {
                            if weight < 100 { weight += 1 }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.cyan)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button(action: {
            onStart(exercise, sets, reps, weight)
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text("ワークアウト開始")
            }
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(colors: [.cyan.opacity(0.8), .blue.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .padding(.bottom, 30)
    }
}

#Preview {
    ExerciseSetupView(
        exercise: .dumbbellPress,
        isPresented: .constant(true),
        onStart: { _, _, _, _ in }
    )
} 