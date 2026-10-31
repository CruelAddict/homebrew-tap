class Resh < Formula
  desc "Native macOS project launcher for Rex"
  homepage "https://github.com/CruelAddict/resh"
  if Hardware::CPU.arm?
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.3/resh-macos-arm64.tar.gz"
    sha256 "89f4e068a6c058ce112c9766ab61ee4e4c88efa3c9d93fca79969f8b71a2ec90"
  else
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.3/resh-macos-x86_64.tar.gz"
    sha256 "1b16a546c51bde6a03e5416cbac1b07cd79aff950f373809704f9e57318e6752"
  end
  version "0.1.3"
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
