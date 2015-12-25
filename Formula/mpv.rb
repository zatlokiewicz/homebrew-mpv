class Mpv < Formula
  desc "Free, open source, and cross-platform media player"
  homepage "https://mpv.io"
  url "https://github.com/mpv-player/mpv/archive/v0.14.0.tar.gz"
  sha256 "042937f483603f0c3d1dec11e8f0045e8c27f19eee46ea64d81a3cdf01e51233"
  head "https://github.com/mpv-player/mpv.git"

  option "with-shared", "Build libmpv shared library."
  option "with-bundle", "Enable compilation of the .app bundle."

  depends_on "pkg-config" => :build
  depends_on :python3

  depends_on "libass"
  depends_on "ffmpeg"

  depends_on "jpeg" => :recommended
  depends_on "little-cms2" => :recommended
  depends_on "lua" => :recommended
  depends_on "youtube-dl" => :recommended

  depends_on "libcaca" => :optional
  depends_on "libdvdread" => :optional
  depends_on "libdvdnav" => :optional
  depends_on "libbluray" => :optional
  depends_on "libaacs" => :optional
  depends_on "vapoursynth" => :optional
  depends_on :x11 => :optional

  depends_on :macos => :mountain_lion

  WAF_VERSION = "waf-1.8.12".freeze

  resource "waf" do
    url "https://waf.io/#{WAF_VERSION}"
    sha256 "01bf2beab2106d1558800c8709bc2c8e496d3da4a2ca343fe091f22fca60c98b"
  end

  resource "docutils" do
    url "https://pypi.python.org/packages/source/d/docutils/docutils-0.12.tar.gz"
    sha256 "c7db717810ab6965f66c8cf0398a98c9d8df982da39b4cd7f162911eb89596fa"
  end

  def install
    # LANG is unset by default on osx and causes issues when calling getlocale
    # or getdefaultlocale in Python. Let's overwrite any user settings and use
    # the default c/posix locale
    ENV["LC_ALL"] = "C"
    ENV.prepend_create_path "PKG_CONFIG_PATH", python_pkg_config_path
    ENV.prepend_create_path "PYTHONPATH", site_packages
    ENV.prepend_create_path "PATH", libexec/"bin"
    python_install("docutils")
    bin.env_script_all_files(libexec/"bin", :PYTHONPATH => ENV["PYTHONPATH"])

    args = ["--prefix=#{prefix}", "--enable-gpl3", "--enable-zsh-comp"]
    args << "--enable-libmpv-shared" if build.with? "libmpv"

    buildpath.install resource("waf").files(WAF_VERSION => "waf")
    system "python3", "waf", "configure", *args
    system "python3", "waf", "install"

    if build.with? "bundle"
      system "python3", "TOOLS/osxbundle.py", "build/mpv"
      prefix.install "build/mpv.app"
    end
  end

  test do
    system "#{bin}/mpv", "--ao=null", test_fixtures("test.wav")
  end

  private

  def site_packages
    python_version = Language::Python.major_minor_version("python3")
    libexec/"lib/python#{python_version}/site-packages"
  end

  def python_pkg_config_path
    Pathname.new(`python3-config --prefix`.chomp)/"lib/pkgconfig"
  end

  def python_install(package)
    resource(package).stage do
      system "python3", *Language::Python.setup_install_args(libexec)
    end
  end
end
