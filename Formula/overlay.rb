class Overlay < Formula
  desc "Translucent HUD overlay for macOS & Linux with instant AI assistance"
  homepage "https://github.com/bogusdeck/overlay"
  url "https://github.com/bogusdeck/overlay/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "9e2c7a4496da827e053e9e0555b180aebd1190c0e351a3abbcc4a799df20d832"
  license "MIT"
  depends_on :macos
  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  service do
    run [opt_bin/"overlay", "--daemon"]
    keep_alive true
    error_log_path var/"log/overlay.log"
    log_path var/"log/overlay.log"
    process_type :interactive
  end

  def caveats
    <<~EOS
      🛸 Overlay installed successfully!

      Start background service:
        brew services start overlay
        # OR
        overlay --start

      Stop background service:
        brew services stop overlay
        # OR
        overlay --stop

      NOTE: Overlay requires macOS Accessibility permissions for global hotkeys.
      Please grant Accessibility access in:
        System Settings -> Privacy & Security -> Accessibility
    EOS
  end

  test do
    assert_predicate bin/"overlay", :exist?
  end
end
