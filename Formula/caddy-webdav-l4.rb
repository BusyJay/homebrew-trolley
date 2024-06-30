class CaddyWebdavL4 < Formula
    desc "Powerful, enterprise-ready, open source web server with automatic HTTPS"
    homepage "https://caddyserver.com/"
    url "https://github.com/caddyserver/caddy.git", revision: "f8861ca16bd475e8519e7dbf5a2b55e81b329874"
    version "2024.06.30"
    license "Apache-2.0"
    conflicts_with "caddy", because: "caddy-webdav-l4 is a modified version of caddy formula."
  
    depends_on "go" => :build
  
    resource "xcaddy" do
      url "https://github.com/caddyserver/xcaddy/archive/refs/tags/v0.4.2.tar.gz"
      sha256 "02e685227fdddd2756993ca019cbe120da61833df070ccf23f250c122c13d554"
    end
  
    def install
      resource("xcaddy").stage do
        system "go", "run", "cmd/xcaddy/main.go", "build", version.commit, "--with", "github.com/mholt/caddy-webdav", "--with", "github.com/mholt/caddy-l4", "--output", bin/"caddy"
      end
  
      generate_completions_from_executable("go", "run", "cmd/caddy/main.go", "completion")
  
      system bin/"caddy", "manpage", "--directory", buildpath/"man"
  
      man8.install Dir[buildpath/"man/*.8"]
    end
  
    def caveats
      <<~EOS
        When running the provided service, caddy's data dir will be set as
          `#{HOMEBREW_PREFIX}/var/lib`
          instead of the default location found at https://caddyserver.com/docs/conventions#data-directory
      EOS
    end
  
    service do
      run [opt_bin/"caddy", "run", "--config", etc/"Caddyfile.json"]
      keep_alive true
      error_log_path var/"log/caddy.log"
      log_path var/"log/caddy.log"
      environment_variables XDG_DATA_HOME: "#{HOMEBREW_PREFIX}/var/lib"
    end
  
    test do
      port1 = free_port
      port2 = free_port
  
      (testpath/"Caddyfile").write <<~EOS
        {
          admin 127.0.0.1:#{port1}
        }
  
        http://127.0.0.1:#{port2} {
          respond "Hello, Caddy!"
        }
      EOS
  
      fork do
        exec bin/"caddy", "run", "--config", testpath/"Caddyfile"
      end
      sleep 2
  
      assert_match "\":#{port2}\"",
        shell_output("curl -s http://127.0.0.1:#{port1}/config/apps/http/servers/srv0/listen/0")
      assert_match "Hello, Caddy!", shell_output("curl -s http://127.0.0.1:#{port2}")
  
      assert_match version.to_s, shell_output("#{bin}/caddy version")
    end
  end