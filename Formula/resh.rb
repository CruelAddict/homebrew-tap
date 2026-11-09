class Resh < Formula
  desc "Native macOS project launcher for Rex"
  homepage "https://github.com/CruelAddict/resh"
  if Hardware::CPU.arm?
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.6/resh-macos-arm64.tar.gz"
    sha256 "5a4c3e3a21222001e4b9b239845dfed8b29625c4c8b064ae79dd6c7d7964ce45"
  else
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.6/resh-macos-x86_64.tar.gz"
    sha256 "849194b99a071c39e4409ad45efc7e1d8d7de168475e62e6aec967e2b0161a21"
  end
  version "0.1.6"
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
