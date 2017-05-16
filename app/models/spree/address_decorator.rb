module SolidusWalletBackport
  module AddressDecorator
    DB_ONLY_ATTRS = %w(id updated_at created_at)

    def self.prepended(base)
      base.extend ActiveModel::ForbiddenAttributesProtection

      # @return [Address] an equal address already in the database or a newly created one
      def base.factory(attributes)
        full_attributes = value_attributes(column_defaults, new(attributes).attributes)
        find_or_initialize_by(full_attributes)
      end

      # @return [Address] address from existing address plus new_attributes as diff
      # @note, this may return existing_address if there are no changes to value equality
      def base.immutable_merge(existing_address, new_attributes)
        # Ensure new_attributes is a sanitized hash
        new_attributes = sanitize_for_mass_assignment(new_attributes)

        return factory(new_attributes) if existing_address.nil?

        merged_attributes = value_attributes(existing_address.attributes, new_attributes)
        new_address = factory(merged_attributes)
        if existing_address == new_address
          existing_address
        else
          new_address
        end
      end

      # @return [Hash] hash of attributes contributing to value equality with optional merge
      def base.value_attributes(base_attributes, merge_attributes = nil)
        # dup because we may modify firstname/lastname.
        base = base_attributes.dup

        base.stringify_keys!

        if merge_attributes
          base.merge!(merge_attributes.stringify_keys)
        end

        # TODO: Deprecate these aliased attributes
        base['firstname'] = base.delete('first_name') if base.key?('first_name')
        base['lastname'] = base.delete('last_name') if base.key?('last_name')

        base.except!(*DB_ONLY_ATTRS)
      end
    end
  end
end

Spree::Address.prepend SolidusWalletBackport::AddressDecorator
