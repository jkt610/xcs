require 'thor'
require 'appscript'
require 'pathname'

class XcodeProxy
  def initialize (path)
    @project = nil
    @project_document = File.basename(path)
    full_path = Pathname.new(path).realpath.to_s
    mac_path = full_path
    mac_path.sub!(/^\//, '')
    mac_path.gsub!(/\//, ':')
    @app = Appscript.app('Xcode')
    @app.open(mac_path)
    prjs = @app.projects.get
    prjs.each do |pr|
      tmp_path = pr.path.get
      if path == tmp_path then
        @project = pr.name.get
      end
    end
  end

  def close
    @app.project_documents[@project_document].close
  end

  def list(verbose = false)
    root_group = @app.projects[@project].root_group
    list_group(root_group, verbose)
  end

  def add(path, group)
    root_group = @app.projects[@project].root_group
    group_ref = find_group(root_group, group)
    if group_ref != nil then
      file = File.basename(path)
      file_ref = group_ref.make(
        :new => :file_reference,
        :with_properties => {
          :name => file,
          :full_path => path
        })

      if file_ref != nil then
        compilable = %w[.cpp .c .C .m .mm]
        compilable.each do |ext|
          if path =~ /#{ext}$/ then
            file_ref.add(:to => @app.projects[@project].targets[1])
            break
          end
        end
      end
    end
  end

  def remove(path)
    filename = File.basename(path)
    group = File.dirname(path)
    root_group = @app.projects[@project].root_group
    group_ref = find_group(root_group, group)
    return if group_ref == nil

    file_refs = group_ref.file_references.get
    file_refs.each do |fref|
      fn = fref.name.get
      if fn == filename then 
        id = fref.id_.get
        group_ref.delete(group_ref.file_references.ID(id))
      end
    end
  end

  def mkgroup(group)
    @app.projects[@project].root_group.make(
      :new => :group, 
      :with_properties => {:name => group}
    )
  end

  def rmgroup(group)
    root_group = @app.projects[@project].root_group
    group_ref = find_group(root_group, group)
    if group_ref == nil then
      puts "Group #{group} not found"
      return
    end
    content = group_ref.item_references.get
    if content.count > 0 then
      puts "Group #{group} is not empty"
      return
    end
    id = group_ref.id_.get
    root_group.delete(root_group.groups.ID(id))
  end

private

  def print_groupref(group_ref, verbose, indent = 0)
    name = group_ref.name.get
    id = group_ref.id_.get
    text = "#{name}"
    text += "(#{id})" if (verbose)
    print "  " * indent
    puts "#{text}/"
  end

  def print_fileref(file_ref, verbose, indent = 0)
    name = file_ref.name.get
    id = file_ref.id_.get
    path = file_ref.full_path.get
    text = "#{name}"
    text += "(#{id}, #{path})" if (verbose)
    print "  " * indent
    puts "#{text}"
  end

  def list_group(group_ref, verbose, indent = 0)
    print_groupref(group_ref, verbose, indent)
    items = group_ref.item_references.get
    items.each do |item| 
      item_class = item.class_.get
      if item_class == :group then
        list_group(item, verbose, indent + 1)
      elsif item_class == :file_reference then
        print_fileref(item, verbose, indent + 1)
      else
        p item_class
      end
    end
  end

  def find_group(group_ref, group_name)
    items = group_ref.item_references.get
    items.each do |item| 
      item_class = item.class_.get
      if item_class == :group then
        name = item.name.get
        return item if (name == group_name)
      end
    end
    return
  end
end

class Xcs < Thor

  def initialize(*args)
    super
    @proxy = nil
  end

  method_options :verbose => :boolean
  desc 'list [--verbose]',  'List project contents'

  def list
    open_project
    @proxy.list(options.verbose?)
  end

  desc 'add File [Group]',  'Add file to a group. By default adds to "Source"'
  def add(path, group)
    open_project
    @proxy.add(File.absolute_path(path), group)
    @proxy.close 
  end

  desc 'rm Group/File',  'Remove file reference from a project'
  def rm(path)
    open_project
    @proxy.remove(path)
    @proxy.close 
  end

  desc 'mkgroup Group',  'Create new subgroup in root group'
  def mkgroup(group)
    open_project
    @proxy.mkgroup(group)
    @proxy.close 
  end

  desc 'rmgroup Group',  'Remove Group'
  def rmgroup(group)
    open_project
    @proxy.rmgroup(group)
    @proxy.close 
  end

  no_tasks { 
    def open_project
      # try to find .xcodeproj file
      cwd = Pathname.new(Dir.pwd)
      project_path = nil
      while true do
        projects = Dir.entries(cwd).grep /.xcodeproj$/
        if projects.count > 1 then
          puts "Confused: more then one .xcodeproj file found"
          exit(1)
        end
        if projects.count == 1 then
          proj_path = (cwd + projects[0]).realpath.to_s
          puts "Using #{proj_path}"

          break
        end
        break if cwd == cwd.parent
        cwd = cwd.parent
      end
      if proj_path == nil then
        puts "No .xcodeproj file found, giving up"
        exit(1)
      end
      @proxy = XcodeProxy.new(proj_path)
    end
  }
end
