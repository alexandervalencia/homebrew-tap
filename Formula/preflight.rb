class Preflight < Formula
  desc "Review branches like GitHub PRs — before pushing upstream"
  homepage "https://github.com/alexandervalencia/preflight"
  url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.1/preflight-server-v0.1.1.tar.gz"
  sha256 "3c258829d0e52c7d46099f58982491496b8e6fa3d8a9a0be0750bcb3948a0b46"
  version "0.1.1"
  license "MIT"

  depends_on "ruby@3.4"
  depends_on "sqlite"

  on_macos do
    on_arm do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.1/preflight-darwin-arm64.tar.gz"
        sha256 "a610ba9599967e64e73d5ab9e030e630050f47d02a3a37aecad8d8f9976880ee"
      end
    end
    on_intel do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.1/preflight-darwin-amd64.tar.gz"
        sha256 "6890a102ae96f25407e3b71a1096c2f9c2a17b93607eed372496a649ea08d640"
      end
    end
  end

  on_linux do
    on_arm do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.1/preflight-linux-arm64.tar.gz"
        sha256 "5b2f00b8979217252524e818ce6d1d79b07c3244f88b8c1d91c720c795797672"
      end
    end
    on_intel do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.1/preflight-linux-amd64.tar.gz"
        sha256 "f856c2f552637ee5e1394582cca0fc773ddad16685b76f3bf893cfe195eb4211"
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
