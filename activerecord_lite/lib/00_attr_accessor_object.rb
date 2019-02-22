class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      #define getter
      get_name = "@#{name}"
      define_method(name) do 
        self.instance_variable_get(get_name.to_sym) 
      end 
      #define setter
      method_name = "#{name}="
      set_name = "@#{name}"
      define_method(method_name.to_sym) do |new_val = nil|
        self.instance_variable_set(set_name.to_sym, new_val)
      end
    end 
  end
end
