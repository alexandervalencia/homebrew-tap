class Preflight < Formula
  desc "Review branches like GitHub PRs — before pushing upstream"
  homepage "https://github.com/alexandervalencia/preflight"
  url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.3/preflight-server-v0.1.3.tar.gz"
  sha256 "7bc9f980f5d8ecb5abd242940264992f0467593c8256dd7b8c3491a4cfd34625"
  version "0.1.3"
  license "MIT"

  depends_on "ruby@3.4"
  depends_on "sqlite"

  on_macos do
    on_arm do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.3/preflight-darwin-arm64.tar.gz"
        sha256 "b3919821f478a0e552f41e84a940a3351e6119bd2f824ad83e5ad4fabb1dce57"
      end
    end
    on_intel do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.3/preflight-darwin-amd64.tar.gz"
        sha256 "729dad38919478ff46e3a284fb203c1632a6c5562242c58ec4f7f433e77281f2"
      end
    end
  end

  on_linux do
    on_arm do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.3/preflight-linux-arm64.tar.gz"
        sha256 "3c44cfd8496c083fb2e215c3c874ebbaaec9ed415cf2075d4b19c81555b0429e"
      end
    end
    on_intel do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.3/preflight-linux-amd64.tar.gz"
        sha256 "996265d8d3f8f5a0cb386142a984a6b1adbbb26710f41b1366de31407e5a2957"
      end
    end
  end

  def install
    # Install the Rails server (primary download)
    libexec.install Dir["*"]
    chmod 0755, libexec/"bin/start-server"
    chmod 0755, libexec/"bin/run-rails"

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

    bundle = libexec/"vendor/bundle/bin/bundle"
    system bundle, "config", "set", "--local", "path", (libexec/"vendor/bundle").to_s
    system bundle, "config", "set", "--local", "without", "development:test"
    system bundle, "config", "set", "--local", "gemfile", (libexec/"server/Gemfile").to_s
    system bundle, "install", "--jobs=4", "--retry=3"
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
