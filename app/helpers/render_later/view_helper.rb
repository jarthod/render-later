module RenderLater
  module ViewHelper
    INSERT_FUNCTION = <<-JAVASCRIPT.freeze
      function rl_insert(name, data) {
        if (node = document.getElementById(name)) {
          var div = document.createElement('div');
          div.innerHTML = data;
          var elements = div.childNodes;
          for (var i = elements.length; i > 0; i--) {
            node.parentNode.insertBefore(elements[0], node);
          }
          node.parentNode.removeChild(node);
        }
      };
    JAVASCRIPT

    def render_later key, &block
      store_object(key, &block)
      content_tag(:span, nil, id: "rl-#{key}", class: "rl-placeholder", style: 'display: none')
    end

    def render_now
      return nil if deferred_objects.empty?
      concat content_tag('script', raw(INSERT_FUNCTION))
      deferred_objects.each do |key, block|
        concat content_tag('script', raw("rl_insert('rl-#{key}', '#{j capture(&block)}');\n"))
      end
      nil
    rescue Errno::EPIPE
    end

    private

    def store_object key, &block
      objects = deferred_objects
      raise Error, "duplicate key: #{key}" if objects.has_key?(key)
      objects[key] = block
      request.instance_variable_set(:@deferred_objects, objects)
    end

    def deferred_objects
      if request.instance_variable_defined?(:@deferred_objects)
        request.instance_variable_get(:@deferred_objects)
      else
        {}
      end
    end
  end
end