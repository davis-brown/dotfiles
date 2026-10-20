-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Open Firefox on workspace 1 and Ghostty on workspace 2 at login. "silent"
-- places each window without switching to its workspace.
hl.on("hyprland.start", function()
  hl.exec_cmd(o.launch("firefox"), { workspace = "1 silent" })
  hl.exec_cmd(o.launch("ghostty"), { workspace = "2 silent" })
end)
