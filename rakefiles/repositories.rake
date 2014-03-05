# GistID: 1924422
# Author:: Couchbase <info@couchbase.com>
# Copyright:: 2011, 2012 Couchbase, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This is a collection of the task helping to maintain RPM and DEB
# repositories.
#
# USAGE
# =====
#
# The most interesting and useful tasks are:
#
# Synchronize DEB/RPM repositories with Amazon S3. (First time it should
# create master copy of the repositories at HOME. The target s3 bucket
# should be specified in S3_PKG_MIRROR environment variable (for example
# s3://packages.example.com)
#
#   * rake -g master:sync
#
# Tasks to upload artifacts from current directory. You should specify the
# target master host in MASTER_HOST environment variable (for example
# master@masternode.com)
#
#   * rake -g builder:deb:upload:lucid
#   * rake -g builder:deb:upload:oneiric
#   * rake -g builder:deb:upload:sid
#   * rake -g builder:rpm:upload:centos5.5
#   * rake -g builder:rpm:upload:centos6.2
#
# You can see all tasks with -T switch
#
#   * rake -g -T
#
# INSTALLATION
# ============
#
# $ sudo apt-get install rake reprepro createrepo s3cmd
# $ mkdir $HOME/.rake
# $ cp repositories.rake $HOME/.rake/
#
# Also make sure that all instances have GPG keys to sign the packages and
# the repository itself.
#
# Following crontab stuff helps to import incoming packages automatically
# every 5 minutes
#
#   S3_PKG_MIRROR=s3://package.example.net
#   DPKG_GPG_KEY=872CF7D3
#   HOME=/home/master
#   */5 * * * * /usr/bin/rake -g master:sync > /dev/null
#
# To create special branches (like preview) use PREFIX environment variable
#
require 'pathname'

if ENV['MASTER_IS_LOCAL'] 
  COPY_TOOL='cp'
  MASTER_HOST=ENV['MASTER_HOST'] || ''
else
  MASTER_HOST="#{ENV['MASTER_HOST']}:"
  COPY_TOOL='scp'
end

REPOROOT="#{MASTER_HOST}/#{ENV['LCB_REPO_PREFIX']}"

namespace :builder do
  desc "Check the builder readiness"
  task :check do
    abort if tool_is_missing("ssh -V", "openssh-client") ||
      tool_is_missing("gpg --version", "gnupg") ||
      (var_is_missing("MASTER_HOST") && var_is_missing("MASTER_IS_LOCAL"))
  end

  namespace :deb do
    ["lucid", "oneiric", "precise"].each do |dist|
      desc "Upload DEB packages for Ubuntu #{dist}"
      task "upload:#{dist}" => :check do
        Dir["*.{changes,deb,dsc,tar.gz}"].each do |file|
          sh("#{COPY_TOOL} #{file} #{REPOROOT}ubuntu/incoming/#{dist}")
        end
      end
    end
  end

  namespace :rpm do
    ["5.5", "6.2"].each do |dist|
      desc "Upload RPM packages for CentOS #{dist}"
      task "upload:centos#{dist}" => :check do
        Dir["*.rpm"].each do |file|
          sh("#{COPY_TOOL} #{file} #{REPOROOT}rpm/#{dist}/incoming")
        end
      end
    end
  end
end

namespace :master do
  desc "Check the master readiness"
  task :check do
    abort if var_is_missing("HOME") ||
      file_is_missing(File.join(File.dirname(__FILE__), 'sign_rpm.expect'), "copy sign_rpm.expect script to #{File.dirname(__FILE__)}")
    PREFIX = Pathname.new(ENV['HOME'])
    if ENV['LCB_REPO_PREFIX']
      PREFIX = PREFIX.join(ENV['LCB_REPO_PREFIX'])
    end
  end

  namespace :deb do
    desc "Populate DEB repository structure"
    task :seed => :check do
      repo = PREFIX.join("ubuntu")
      unless repo.join(".checkpoint").exist?
        mkdir_p(repo.join("conf"))
        ubuntu_dists = {"lucid" => "10.04", "oneiric" => "11.10", "precise" => "12.04"}
        File.open(repo.join("conf", "distributions"), "w+") do |f|
          ubuntu_dists.each do |name, ver|
            mkdir_p(repo.join("pool"))
            mkdir_p(repo.join("dists", name))
            mkdir_p(repo.join("incoming", name))
            mkdir_p(repo.join("incoming-deb", name))
            f.puts(<<-EOC.gsub(/^\s+/, ''))
              Origin: couchbase
              SignWith: #{ENV['APT_GPG_KEY']}
              Suite: #{name}
              Codename: #{name}
              Version: #{ver}
              Components: #{name}/main
              Architectures: amd64 i386 source
              Description: Couchbase package repository
            EOC
            f.puts
          end
        end
        touch(repo.join(".checkpoint"))
      end
    end

    desc "Import DEB packages from incoming queues"
    task :import => :seed do
      repo = PREFIX.join("ubuntu")
      # import from incoming (only .change files)
      incoming = repo.join('incoming')
      Dir[incoming.join('*')].each do |path|
        if File.directory?(path)
          codename = File.basename(path)
          Dir[File.join(path, "*.changes")].each do |change|
            sh("reprepro -T deb -V --ignore=wrongdistribution -b #{repo} include #{codename} #{change}")
          end
          FileUtils.rm_rf(Dir[File.join(path, "*")])
        end
      end
      # import plain deb files (this is how the server ship packages)
      incoming = repo.join('incoming-deb')
      Dir[incoming.join('*')].each do |path|
        if File.directory?(path)
          codename = File.basename(path)
          Dir[File.join(path, "*.deb")].each do |package|
            sh("reprepro -T deb -V --ignore=wrongdistribution -b #{repo} includedeb #{codename} #{package}")
          end
          FileUtils.rm_rf(Dir[File.join(path, "*")])
        end
      end
      # fix S3 space handling
      names = `find #{repo.join('pool')} -name '*+*'`.split
      names.each do |name|
        FileUtils.cp(name, name.sub('+', ' '))
        FileUtils.cp(name, name.sub('+', '%2B'))
      end
    end

    desc "Syncronize Amazon S3 mirrors for DEB repositories"
    task :sync => :import do
      repo = PREFIX.join("ubuntu")
      sh("s3cmd sync -P #{repo}/ #{ENV['S3_PKG_MIRROR']}/#{ENV['PREFIX']}ubuntu/")
    end
  end

  namespace :rpm do
    desc "Populate RPM repository structure"
    task :seed => :check do
      repo = PREFIX.join("rpm")
      unless repo.join(".checkpoint").exist?
        ["5.5", "6.2"].each do |ver|
          mkdir_p(repo.join(ver, "incoming"))
          ["i686", "i386", "x86_64", "SRPMS"].each do |arch|
            mkdir_p(repo.join(ver, arch))
            sh("createrepo --checksum sha #{repo.join(ver, arch)}")
          end
        end
        touch(repo.join(".checkpoint"))
      end
    end

    desc "Import RPM packages from incoming queues"
    task :import => :seed do
      repo = PREFIX.join("rpm")
      ["5.5", "6.2"].each do |ver|
        incoming = repo.join(ver, 'incoming')
        map = {'*.src.rpm' => 'SRPMS',
               '*.x86_64.rpm' => 'x86_64',
               '*.i686.rpm' => 'i686',
               '*.i386.rpm' => 'i386'}

        map.each do |glob, target|
          Dir[incoming.join(glob)].each do |pkg|
            FileUtils.mv(pkg, repo.join(ver, target))
          end
          puts repo.join(ver, target)
          if File.exists?(repo.join(ver, target))
            sh("createrepo --update --checksum sha #{repo.join(ver, target)}")
          end
        end
      end
    end

    desc "Sign RPM repository"
    task :sign => :seed do
      repo = PREFIX.join("rpm")
      abort if var_is_missing('RPM_GPG_KEY')
      sh("expect #{File.join(File.dirname(__FILE__), "sign_rpm.expect")} #{ENV['RPM_GPG_KEY']} #{repo}")
      ["5.5", "6.2"].each do |ver|
        ['SRPMS', 'x86_64', 'i386', 'i686'].each do |target|
          if File.exists?(repo.join(ver, target, 'repodata/repomd.xml'))
            sh("gpg --batch --yes -u #{ENV['RPM_GPG_KEY']} --detach-sign --armor #{repo.join(ver, target, 'repodata/repomd.xml')}")
          end
        end
      end
    end

    desc "Syncronize Amazon S3 mirrors for RPM repositories"
    task :sync => [:check, :import, :sign] do
      repo = PREFIX.join("rpm")
      sh("s3cmd sync -P #{repo}/ #{ENV['S3_PKG_MIRROR']}/#{ENV['PREFIX']}rpm/")
    end
  end

  desc "Synchronyze all repositories"
  task :sync => ["deb:sync", "rpm:sync"]
end

def tool_is_missing(command, package)
  print "checking for #{package} tool ... "
  `#{command} >/dev/null 2>&1`
  unless $?.success?
    puts("missing. apt-get install #{package}")
    return true
  end
  puts `which #{command.split(' ').first}`.chomp
  return false
end

def var_is_missing(name)
  print "checking for #{name} variable ... "
  if ENV[name].nil? || ENV[name].empty?
    puts "missing"
    return true
  end
  puts ENV[name]
  return false
end

def file_is_missing(name, message)
  print "checking for #{name} file ... "
  if name.nil? || !File.exist?(name)
    puts("missing. #{message}")
    return true
  end
  puts 'ok'
  return false
end
