class Preflight < Formula
  desc "Review branches like GitHub PRs — before pushing upstream"
  homepage "https://github.com/alexandervalencia/preflight"
  version "0.1.0"
  license "MIT"

  depends_on "ruby@3.4"
  depends_on "sqlite"

  on_macos do
    if Hardware::CPU.arm?
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v#{version}/preflight-darwin-arm64.tar.gz"
        sha256 "PLACEHOLDER"
      end
    else
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v#{version}/preflight-darwin-amd64.tar.gz"
        sha256 "PLACEHOLDER"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v#{version}/preflight-linux-arm64.tar.gz"
        sha256 "PLACEHOLDER"
      end
    else
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v#{version}/preflight-linux-amd64.tar.gz"
        sha256 "PLACEHOLDER"
      end
    end
  end

  resource "server" do
    url "https://github.com/alexandervalencia/preflight/releases/download/v#{version}/preflight-server-v#{version}.tar.gz"
    sha256 "PLACEHOLDER"
  end

  def install
    # Install the Go CLI binary
    resource("cli").stage do
      bin.install "preflight"
    end

    # Install the Rails server
    resource("server").stage do
      libexec.install Dir["*"]
    end

    # Make start-server executable
    chmod 0755, libexec/"bin/start-server"

    # Install gems using Homebrew's Ruby
    ruby = Formula["ruby@3.4"].opt_bin/"ruby"
    gem = Formula["ruby@3.4"].opt_bin/"gem"
    bundle = Formula["ruby@3.4"].opt_bin/"bundle"

    # Ensure bundler is available
    system gem, "install", "bundler", "--no-document",
           "--install-dir", libexec/"vendor/bundle"

    ENV["GEM_HOME"] = libexec/"vendor/bundle"
    ENV["GEM_PATH"] = libexec/"vendor/bundle"
    ENV["BUNDLE_PATH"] = libexec/"vendor/bundle"
    ENV["BUNDLE_GEMFILE"] = libexec/"server/Gemfile"
    ENV["PATH"] = "#{libexec}/vendor/bundle/bin:#{Formula["ruby@3.4"].opt_bin}:#{ENV["PATH"]}"

    system bundle, "install",
           "--gemfile=#{libexec}/server/Gemfile",
           "--path=#{libexec}/vendor/bundle",
           "--without=development:test",
           "--jobs=4",
           "--retry=3"
  end

  def caveats
    <<~EOS
      Preflight runs a local server on port 4500.

      To export PRs to GitHub, install the GitHub CLI:
        brew install gh

      Get started:
        cd your-repo
        preflight push
    EOS
  end

  test do
    assert_match "Local PR review", shell_output("#{bin}/preflight --help")
  end
end
