# plugin architecture design for `soak`

### 1. overview

the goal is to allow developers to extend `soak` with custom scraping logic
for specific sites or platforms (e.g., confluence, zendesk, etc.). this will
be achieved by treating the existing crawler as the "default" plugin and
introducing a system for discovering and registering new, optional plugins.

the command-line interface will be updated to support invoking these plugins
as subcommands, like `soak confluence <url>`.

### 2. core concepts

1.  **plugin as a class:** each plugin will be a ruby class that encapsulates
    the logic for a specific scraping task. it will be responsible for its own
    command-line options and execution flow.

2.  **base plugin (the contract):** a `soak::plugins::base` class will be
    created to establish a common interface. all plugins must inherit from
    this class. this ensures that the cli can interact with every plugin in a
    consistent way.

3.  **automatic registration:** plugins will automatically register themselves
    with the main application. this will be achieved using ruby's `inherited`
    hook. when a class inherits from `soak::plugins::base`, its descendant
    class will be added to a central registry.

4.  **dynamic cli commands:** the main `soak::cli` class will be modified to
    dynamically load all plugins from the registry and create a `thor`
    subcommand for each one. this makes the cli extensible simply by adding a
    new plugin file.

### 3. implementation details

**a. project structure**

a new directory, `lib/soak/plugins/`, will be created to house the plugin
files.

```
soak/
├── lib/
│   ├── soak/
│   │   ├── plugins/
│   │   │   ├── base.rb       # the base class for all plugins
│   │   │   └── confluence.rb # an example plugin
│   │   ├── cli.rb
│   │   ├── crawler.rb
│   │   ├── ...
│   └── soak.rb
└── ...
```

**b. the base plugin and registration**

the `base.rb` file will define the registration logic and the required
interface.

```ruby
# lib/soak/plugins/base.rb
module Soak
  module Plugins
    class base < thor
      def self.plugins
        @plugins ||= []
      end

      def self.inherited(descendant)
        super
        # register the new plugin class
        soak::plugins::base.plugins << descendant
      end

      def self.plugin_name
        # convention: convert class name from 'soak::plugins::confluence' to 'confluence'
        name.split('::').last.downcase
      end
    end
  end
end
```

**c. cli integration**

the `cli.rb` file will be updated to load plugins and register them as `thor`
subcommands.

```ruby
# lib/soak/cli.rb
require 'thor'
require_relative 'crawler'
require_relative 'plugins/base' # load the base plugin first

# dynamically load all other plugin files
dir[file.join(__dir__, 'plugins', '*.rb')].each { |file| require file }

module soak
  class cli < thor
    # the original 'crawl' command is preserved
    desc "crawl url [depth]", "crawl a website starting at url to a given depth"
    def crawl(url, depth = 2)
      # ... existing implementation ...
    end

    # register each discovered plugin as a subcommand
    soak::plugins::base.plugins.each do |plugin_class|
      register(plugin_class, plugin_class.plugin_name, "#{plugin_class.plugin_name} [options]", "run the #{plugin_class.plugin_name} plugin")
    end
  end
end
```

### 4. example: a confluence plugin

a user wanting to implement the confluence plugin would create the following
file:

```ruby
# lib/soak/plugins/confluence.rb
require_relative 'base'

module soak
  module plugins
    class confluence < base
      desc "confluence url", "soak a confluence page and its children"
      
      # define plugin-specific options
      option :api_key, type: :string, desc: "confluence api key"
      option :username, type: :string, desc: "confluence username"

      def crawl(url)
        # --- plugin-specific logic would go here ---
        
        # 1. use the 'options' hash to get api key, etc.
        api_key = options[:api_key]
        
        # 2. use the confluence rest api to find child and sibling pages.
        #    (this would involve making api calls with faraday).
        
        # 3. for each page found, use the core soak components to
        #    download, clean, and save it.
        #    pages_to_soak.each do |page_url|
        #      html = soak::fetcher.fetch(page_url)
        #      cleaner = soak::cleaner.new(html, page_url)
        #      saver = soak::saver.new(cleaner.markdown, page_url)
        #      saver.save
        #      puts "saved #{page_url}"
        #    end
        
        puts "soaking confluence page at #{url}..."
        puts "using api key: #{api_key}" if api_key
      end
    end
  end
end
```

with this structure, the user could run `soak help` and see `crawl` and
`confluence` as available commands. this design is clean, decoupled, and makes
adding new functionality straightforward.

