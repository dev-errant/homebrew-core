class Broot < Formula
  desc "New way to see and navigate directory trees"
  homepage "https://dystroy.org/broot/"
  url "https://github.com/Canop/broot/archive/v1.9.0.tar.gz"
  sha256 "f4de9c64e9619825ccfe330136cde4fd775d78cb7710d18c84a5e6cdae8400c9"
  license "MIT"
  head "https://github.com/Canop/broot.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_monterey: "41cd7481be145ca41cc515b3c899d522d79f124c355e79c49a78d99c81396d76"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "4f4ad4f2436dc28ad15c00ecc2a0b7cb0914ba999dc571dc8609eb5285b54490"
    sha256 cellar: :any_skip_relocation, monterey:       "1e765104e664f12aa61db362ffcf4142cabfb447ac91892b7a4ca4d919786487"
    sha256 cellar: :any_skip_relocation, big_sur:        "d79b39d4d82ca7d7245c25c80b9782a690aa3b5aab070fec44c3593a7e3615bf"
    sha256 cellar: :any_skip_relocation, catalina:       "53178b31b5ea5cae27e6bdc6a14c3e15380a7248ba1f1779031fae3ed61f1dcf"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "6351afb670f1145ab709cf28ac89dd72e1ad5b4a0cfa1f8d9a5a42775ec2c1b6"
  end

  depends_on "rust" => :build
  depends_on "libxcb"

  uses_from_macos "curl" => :build
  uses_from_macos "zlib"

  def install
    system "cargo", "install", *std_cargo_args

    # Replace man page "#version" and "#date" based on logic in release.sh
    inreplace "man/page" do |s|
      s.gsub! "#version", version
      s.gsub! "#date", time.strftime("%Y/%m/%d")
    end
    man1.install "man/page" => "broot.1"

    # Completion scripts are generated in the crate's build directory,
    # which includes a fingerprint hash. Try to locate it first
    out_dir = Dir["target/release/build/broot-*/out"].first
    bash_completion.install "#{out_dir}/broot.bash"
    bash_completion.install "#{out_dir}/br.bash"
    fish_completion.install "#{out_dir}/broot.fish"
    fish_completion.install "#{out_dir}/br.fish"
    zsh_completion.install "#{out_dir}/_broot"
    zsh_completion.install "#{out_dir}/_br"
  end

  test do
    on_linux do
      return if ENV["HOMEBREW_GITHUB_ACTIONS"]
    end

    assert_match "A tree explorer and a customizable launcher", shell_output("#{bin}/broot --help 2>&1")

    require "pty"
    require "io/console"
    PTY.spawn(bin/"broot", "--cmd", ":pt", "--color", "no", "--out", testpath/"output.txt", err: :out) do |r, w, pid|
      r.winsize = [20, 80] # broot dependency termimad requires width > 2
      w.write "n\r"
      assert_match "New Configuration file written in", r.read
      Process.wait(pid)
    end
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
