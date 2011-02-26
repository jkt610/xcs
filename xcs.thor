require 'thor'
require 'appscript'
require 'pathname'

class XcodeProxy
  def initialize (project)
    @app = Appscript.app('Xcode')
    @app.open(project)
  end

  def list(verbose = false)
    root_group = @app.projects[1].root_group
    list_group(root_group, verbose)
  end

  def add(path, group)
    root_group = @app.projects[1].root_group
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
            file_ref.add(:to => @app.projects[1].targets[1])
            break
          end
        end
      end
    end
  end

  def remove(path)
    filename = File.basename(path)
    group = File.dirname(path)
    root_group = @app.projects[1].root_group
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
    @app.projects[1].root_group.make(
      :new => :group, 
      :with_properties => {:name => group}
    )
  end

  def rmgroup(group)
    root_group = @app.projects[1].root_group
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
  @@proxy = XcodeProxy.new('Users:gonzo:Projects:FTool:FTool.xcodeproj')
  method_options :verbose => :boolean
  desc 'list [--verbose]',  'List project contents'
  def list
    @@proxy.list(options.verbose?)
  end

  desc 'add File [Group]',  'Add file to a group. By default adds to "Source"'
  def add(path, group)
    @@proxy.add(File.absolute_path(path), group)
  end

  desc 'rm Group/File',  'Remove file reference from a project'
  def rm(path)
    @@proxy.remove(path)
  end

  desc 'mkgroup Group',  'Create new subgroup in root group'
  def mkgroup(group)
    @@proxy.mkgroup(group)
  end

  desc 'rmgroup Group',  'Remove Group'
  def rmgroup(group)
    @@proxy.rmgroup(group)
  end
end
