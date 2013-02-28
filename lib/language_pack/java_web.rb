require "language_pack/java"
require "fileutils"

# TODO logging
module LanguagePack
  class JavaWeb < Java

    VIRGO_URL =  "https://dl.dropbox.com/u/2487064/virgo-tomcat-server-3.6.1.RELEASE.zip".freeze
    WEBAPP_DIR = "webapps/ROOT/".freeze

    def self.use?
      File.exists?("META-INF/MANIFEST.MF")
    end

    def name
      "Virgo Web"
    end

    def compile
      Dir.chdir(build_path) do
        install_java
        install_virgo
        remove_virgo_files
        copy_webapp_to_virgo
        move_virgo_to_root
        copy_resources
        setup_profiled
      end
    end

    def install_virgo
      FileUtils.mkdir_p virgo_dir
      virgo_tarball="#{virgo_dir}/virgo.zip"

      download_virgo virgo_tarball

      puts "Unpacking Virgo to #{virgo_dir}"
      run_with_err_output("tar xzf #{virgo_tarball} -C #{virgo_dir} && mv #{virgo_dir}/virgo-*/* #{virgo_dir} && " +
              "rm -rf #{virgo_dir}/virgo-*")
      FileUtils.rm_rf virgo_tarball
      unless File.exists?("#{virgo_dir}/bin/startup.sh")
        puts "Unable to retrieve Virgo"
        exit 1
      end
    end

    def download_virgo(virgo_zip)
      puts "Downloading Virgo: #{VIRGO_URL}"
      run_with_err_output("curl --silent --location #{VIRGO_URL} --output #{virgo_zip}")
    end

    def remove_virgo_files
      %w[notice.html About*.* about_files epl-v10.html docs work/.].each do |file|
        FileUtils.rm_rf("#{virgo_dir}/#{file}")
      end
    end

    def virgo_dir
      ".virgo"
    end

    def copy_webapp_to_virgo
      run_with_err_output("mv * #{virgo_dir}/pickup")
    end

    def move_virgo_to_root
      run_with_err_output("mv #{virgo_dir}/* . && rm -rf #{virgo_dir}")
    end

    def copy_resources
      # Configure server.xml with variable HTTP port
      run_with_err_output("cp -r #{File.expand_path('../../../resources/virgo', __FILE__)}/* #{build_path}")
    end

    def java_opts
      # TODO proxy settings?
      # Don't override Virgo's temp dir setting
      opts = super.merge({ "-Dhttp.port=" => "$VCAP_APP_PORT" })
      opts.delete("-Djava.io.tmpdir=")
      opts
    end

    def default_process_types
      {
        "web" => "./bin/startup.sh -clean"
      }
    end

  end
end