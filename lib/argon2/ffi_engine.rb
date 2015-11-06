require 'ffi'
require 'ffi-compiler/loader'

module Argon2
  module Ext
    extend FFI::Library
     ffi_lib FFI::Compiler::Loader.find('argon2_wrap')
#int hash_argon2i(void *out, size_t outlen, const void *in, size_t inlen,
#                 const void *salt, size_t saltlen, unsigned int t_cost,
#                 unsigned int m_cost);

   attach_function :hash_argon2i, [:pointer, :size_t, :pointer, :size_t, 
   :pointer, :size_t, :uint, :uint ], :int, :blocking => true

#void argon2_wrap(uint8_t *out, char *pwd, uint8_t *salt, uint32_t t_cost,
#        uint32_t m_cost, uint32_t lanes);
    attach_function :argon2_wrap, [:pointer, :pointer, :pointer, :uint, :uint, :uint], :uint, :blocking => true

  end

  class Engine
    # The engine class shields users from the FFI interface.
    # It is generally not advised to directly use this class.
    def self.hash_argon2i(password, salt, t_cost, m_cost)
      result = ''
      FFI::MemoryPointer.new(:char, Constants::OUT_LEN) do |buffer|
        ret = Ext.hash_argon2i(buffer, Constants::OUT_LEN, password, password.length, salt, salt.length, t_cost, (1<<m_cost))
        raise ArgonHashFail.new(ERRORS[ret]) unless ret == 0
        result = buffer.read_string(Constants::OUT_LEN)
      end
       result.unpack('H*').join
    end

    def self.hash_argon2i_encode(password, salt, t_cost, m_cost)
      result = ''
      if salt.length != Constants::SALT_LEN
        raise ArgonHashFail.new("Invalid salt size") 
      end
      FFI::MemoryPointer.new(:char, 300) do |buffer|
        ret = Ext.argon2_wrap(buffer, password, salt, t_cost, (1<<m_cost), 1)
        raise ArgonHashFail.new(ERRORS[ret]) unless ret == 0
        result = buffer.read_string(300)
      end
      result.gsub("\0", '')
    end
  end
end
