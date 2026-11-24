class Resh < Formula
  desc "Native macOS project launcher for Rex"
  homepage "https://github.com/CruelAddict/resh"
  if Hardware::CPU.arm?
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.7/resh-macos-arm64.tar.gz"
    sha256 "56d8e9e1a7e6b01256782b6904bd8bf54595fbddae66405695af8831208c740b"
  else
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.7/resh-macos-x86_64.tar.gz"
    sha256 "cd75408f74f95bde54ce004a0a379d5eab7fa594e6b77e4cbb29cf5b03d5c7bb"
  end
  version "0.1.7"
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
