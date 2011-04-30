# I have been testing using (from up to date git repo - will delete changes!):
# git reset --hard HEAD; git clean -fdx; rake db:create db:migrate; echo -e "require 'lib/admin_scaffold_for_models'\nAdminScaffoldForModels.create('admin','*')\nexit" | rails console; passenger start;

module AdminScaffoldForModels

  def self.create(section, model='*')
    execute "rails generate controller #{section}/#{section}"
    models = Dir["app/models/#{model}.rb"].map {|f| File.basename(f, '.*').camelize.constantize}
    models.each do |m|
      line = "rails generate scaffold #{section}/#{m.to_s.downcase}"
      m.columns_hash.each do |k, v|
        if k != 'created_at' && k != 'updated_at' && k != 'type' && k != 'id'
          line += " #{k}:#{v.type} "
        end
      end
      execute line
      # User -> User
      execute "find . -type f | xargs perl -pi -e 's/#{section.capitalize}::#{m.to_s}/#{m.to_s}/g'"

      # @user -> @user
      execute "find . -type f | xargs perl -pi -e 's/\\@#{section}_#{m.to_s.downcase}/\\@#{m.to_s.downcase}/g'"

      #Ê:user -> :user
      execute "find . -type f | xargs perl -pi -e 's/\\:#{section}_#{m.to_s.downcase}/\\:#{m.to_s.downcase}/g'"

      #Êform_for([:admin, @user]) -> form_for([:admin, 
      execute "find . -type f | xargs perl -pi -e 's/form_for\\(\\@#{m.to_s.downcase}\\)/form_for\\(\\[\\:#{section}, \\@#{m.to_s.downcase}\\]\\)/g'"

      # UsersController < Admin::AdminController -> UsersController < Admin::AdminController
      execute "find . -type f | xargs perl -pi -e 's/#{m.to_s.pluralize}Controller \\< ApplicationController/#{section.capitalize}::#{m.to_s.pluralize}Controller \\< #{section.capitalize}::#{section.capitalize}Controller/g'"

      # redirect_to([:admin, @user] -> redirect_to([:admin, @user]
      execute "find . -type f | xargs perl -pi -e 's/redirect_to\\(\\@#{m.to_s.downcase}/redirect_to\\(\\[\\:#{section}, \\@#{m.to_s.downcase}\\]/g'"

      # , admin_user -> , [:admin, user] - For Show & Destroy
      execute "echo './app/views/#{section}/#{m.to_s.downcase.pluralize}/index.html.erb' | xargs perl -pi -e \"s/, #{section}_#{m.to_s.downcase}/, \\[\\:#{section}, #{m.to_s.downcase}\\]/g\""

      # 'Show', @user -> 'Show', [:admin, @user]
      execute "echo './app/views/#{section}/#{m.to_s.downcase.pluralize}/edit.html.erb' | xargs perl -pi -e 's/, \\@#{m.to_s.downcase}/, [\\:#{section}, \\@#{m.to_s.downcase}\\]/g'"

      # edit_admin_user_path(admin_user) -> edit_admin_user_path(user) - For Show and destroy
      execute "echo './app/views/#{section}/#{m.to_s.downcase.pluralize}/index.html.erb' | xargs perl -pi -e 's/edit_#{section}_#{m.to_s.downcase}_path\\(#{section}_#{m.to_s.downcase}\\)/edit_#{section}_#{m.to_s.downcase}_path\\(#{m.to_s.downcase}\\)/g'"

      # redirect_to([:admin, @user] -> redirect_to([:admin, @user]
      execute "find . -type f | xargs perl -pi -e 's/do \\|#{section}_#{m.to_s.downcase}\\|/do \\|#{m.to_s.downcase}\\|/g'"

      # user. -> user.
      execute "find . -type f | xargs perl -pi -e 's/#{section}_#{m.to_s.downcase}\\./#{m.to_s.downcase}\\./g'"

    end  
    execute "rm -rf app/helpers/#{section}/"
    execute "rm -rf app/models/#{section}/"
    execute "rm -rf test/fixtures/#{section}/"
    execute "rm -rf test/unit/#{section}/"
    return nil
  end
  def self.execute(command)
    puts command
    system command
  end
end
