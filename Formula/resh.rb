class Resh < Formula
  desc "Native macOS project launcher for Rex"
  homepage "https://github.com/CruelAddict/resh"
  if Hardware::CPU.arm?
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.8/resh-macos-arm64.tar.gz"
    sha256 "17025194494080654790db13506c597725caf1d0f2b00829888441ffc63c206f"
  else
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.8/resh-macos-x86_64.tar.gz"
    sha256 "fca2f9a6b1f4dda249ac3802285a67c56395415b4f8063d838e31f46d68314e1"
  end
  version "0.1.8"
  license "MIT"

  depends_on macos: :sequoia

  def install
    libexec.install "resh", "resh_Resh.bundle", "rex-actions.lua"
    bin.install_symlink libexec/"resh"
    # Existing installations load this file through a link to opt_libexec.
    (libexec/"resh.lua").write Utils.safe_popen_read(
      libexec/"resh", "print-rex-startup-lua", "--executable", HOMEBREW_PREFIX/"bin/resh"
    )
  end

  def caveats
    <<~EOS
      To complete the installation, run:
        resh setup

      Make sure Remote Control is enabled in Rex Settings → Rex Server.
    EOS
  end

  test do
    assert_match "Usage: resh setup", shell_output("#{bin}/resh setup --help")
    assert_match 'name = "resh_serve"', shell_output("#{bin}/resh print-rex-startup-lua")
    assert_equal "project", shell_output("#{bin}/resh --name #{testpath}/project").strip
    assert_match "Valid", shell_output("#{bin}/resh --check-config")
  end
end
