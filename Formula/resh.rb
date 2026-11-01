class Resh < Formula
  desc "Native macOS project launcher for Rex"
  homepage "https://github.com/CruelAddict/resh"
  if Hardware::CPU.arm?
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.5/resh-macos-arm64.tar.gz"
    sha256 "1caad4043b50609ce36dac728ddea6f5e9f8f58a7941c59cf3d17969ed12074a"
  else
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.5/resh-macos-x86_64.tar.gz"
    sha256 "2a82fd74ca5627880ce47256b3194e0e1f999e1116d57327a8ff71937636b561"
  end
  version "0.1.5"
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
