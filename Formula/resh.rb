class Resh < Formula
  desc "Native macOS project launcher for Rex"
  homepage "https://github.com/CruelAddict/resh"
  if Hardware::CPU.arm?
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.2/resh-macos-arm64.tar.gz"
    sha256 "5624d48d491893a3cdcca7946046191d0341a88b8182dba8b87250338fcbda20"
  else
    url "https://github.com/CruelAddict/resh/releases/download/v0.1.2/resh-macos-x86_64.tar.gz"
    sha256 "b721e4a5eda0526141873d28c55f0aac8a3e14ea28219b7fdb1b0cc2cf595e1a"
  end
  version "0.1.2"
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
