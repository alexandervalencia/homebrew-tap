class Preflight < Formula
  desc "Review branches like GitHub PRs — before pushing upstream"
  homepage "https://github.com/alexandervalencia/preflight"
  url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.2/preflight-server-v0.1.2.tar.gz"
  sha256 "3b38cd95fba34236d0bd466eae7630a034a4e87b7858f295b8e4973a7662e878"
  version "0.1.2"
  license "MIT"

  depends_on "ruby@3.4"
  depends_on "sqlite"

  on_macos do
    on_arm do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.2/preflight-darwin-arm64.tar.gz"
        sha256 "298b5e73551e802333f0182bd0265593546e55abc97dc5186e2967ee0f65048a"
      end
    end
    on_intel do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.2/preflight-darwin-amd64.tar.gz"
        sha256 "e2fd544add2003ac764b53d04f6f1d3dddb7a67682b7245c82d6a8553f116184"
      end
    end
  end

  on_linux do
    on_arm do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.2/preflight-linux-arm64.tar.gz"
        sha256 "c584ca6b94390f263596a76e13bd1317ed0595e2d3547492f6e88c3f01657543"
      end
    end
    on_intel do
      resource "cli" do
        url "https://github.com/alexandervalencia/preflight/releases/download/v0.1.2/preflight-linux-amd64.tar.gz"
        sha256 "1f3c9032cd43793fdf744f10266ebb8afb8edbcd745606ae3df539ab2933f178"
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
