# Solara: MainActivity が override する FlutterActivity の method を
# R8 / ProGuard が剥ぎ取らないように保持。
# 特に setFrameworkHandlesBack / register / unregister の no-op override は
# R8 が「親と等価」と判断して削除してしまうため明示的に keep。
-keep class com.solodevlab.solara.MainActivity {
    *;
}

# FlutterActivity の override 対象 method 名を維持 (rename されると override 消失)
-keep class io.flutter.embedding.android.FlutterActivity {
    public void setFrameworkHandlesBack(boolean);
    public void registerOnBackInvokedCallback();
    public void unregisterOnBackInvokedCallback();
}
