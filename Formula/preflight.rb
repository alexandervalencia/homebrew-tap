class Preflight < Formula
  desc "Review branches like GitHub PRs — before pushing upstream"
  homepage "https://github.com/alexandervalencia/preflight"
  url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.0/preflight-server-v0.1.0.tar.gz"
  sha256 "be594a12c624f0966f59eb971cb47c39bdf0468987cda87b07bd249b67270894"
  version "0.1.0"
  license "MIT"

  depends_on "ruby@3.4"
  depends_on "sqlite"

  on_macos do
    on_arm do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.0/preflight-darwin-arm64.tar.gz"
        sha256 "43259a3bfec603a0047360c83d6dddeabb17b201e7c6651f49e893b0c8a37a8b"
      end
    end
    on_intel do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.0/preflight-darwin-amd64.tar.gz"
        sha256 "71d7deee8054c36cca849b404a0266ba61383270884e56d8190ad2817f484fef"
      end
    end
  end

  on_linux do
    on_arm do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.0/preflight-linux-arm64.tar.gz"
        sha256 "c9650f5ffe50fa460f609c9265b7d82e5d1a425b7f7a0a773e7a980ba6e5cc97"
      end
    end
    on_intel do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.0/preflight-linux-amd64.tar.gz"
        sha256 "4d49dc62ca193737ca5345e6309852f1678ec6e852e6a329a21e447039e09d3e"
      end
    end
  end

  def install
    # Install the Rails server (primary download)
    libexec.install Dir["*"]
    chmod 0755, libexec/"bin/start-server"

    # Install the Go CLI binary
    resource("cli").stage do
      bin.install "preflight"
    end

    # Install gems using Homebrew's Ruby
    ruby_bin = Formula["ruby@3.4"].opt_bin
    ENV["GEM_HOME"] = libexec/"vendor/bundle"
    ENV["GEM_PATH"] = libexec/"vendor/bundle"
    ENV["BUNDLE_PATH"] = libexec/"vendor/bundle"
    ENV["BUNDLE_GEMFILE"] = libexec/"server/Gemfile"
    ENV["PATH"] = "#{libexec}/vendor/bundle/bin:#{ruby_bin}:#{ENV["PATH"]}"

    system ruby_bin/"gem", "install", "bundler", "--no-document",
           "--install-dir", libexec/"vendor/bundle"

    system libexec/"vendor/bundle/bin/bundle", "install",
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
