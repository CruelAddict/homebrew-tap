class Resh < Formula
  desc "Native macOS project launcher for Rex"
  homepage "https://github.com/CruelAddict/resh"
  if Hardware::CPU.arm?
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.0/resh-macos-arm64.tar.gz"
    sha256 "3e7f5fc836e3c91e1493b19602d33efa6e793d6e5963cfde41ab2163221d19d0"
  else
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.0/resh-macos-x86_64.tar.gz"
    sha256 "f95432ecc2eeed0b493c06011571b17c005312527c71c7edbe8ee6fc248c4caa"
  end
  version "0.1.0"
  license "MIT"

  depends_on macos: :sequoia

  def install
    libexec.install "resh", "resh_Resh.bundle", "resh.lua", "rex-actions.lua"
    bin.write_exec_script libexec/"resh"
    (libexec/".resh-prefix").write "#{opt_libexec}\n"
  end

  def caveats
    <<~EOS
      Start Rex and enable Settings → Rex Server → Remote Control, then run:

        resh setup

      After upgrading: rex config reload && resh service restart
      Before uninstalling: resh service stop, then remove the resh integration
      from your Rex init.lua.
    EOS
  end

  test do
    assert_match "Usage: resh setup", shell_output("#{bin}/resh setup --help")
    assert_equal "project", shell_output("#{bin}/resh --name #{testpath}/project").strip
    assert_match "Valid", shell_output("#{bin}/resh --check-config")
  end
end
