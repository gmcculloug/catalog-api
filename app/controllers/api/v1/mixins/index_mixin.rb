module Api
  module V1
    module Mixins
      module IndexMixin
        def scoped(relation, pre_authorized)
          relation = rbac_scope(relation, :pre_authorized => pre_authorized) if Insights::API::Common::RBAC::Access.enabled?
          if relation.model.respond_to?(:taggable?) && relation.model.taggable?
            ref_schema = {relation.model.tagging_relation_name => :tag}

            relation = relation.includes(ref_schema).references(ref_schema)
          end
          relation
        end

        def collection(base_query, pre_authorized: false)
          render :json => Insights::API::Common::PaginatedResponse.new(
            :base_query => filtered(scoped(base_query, pre_authorized)),
            :request    => request,
            :limit      => pagination_limit,
            :offset     => pagination_offset,
            :sort_by    => query_sort_by
          ).response
        end

        def rbac_scope(relation, pre_authorized: false)
          return relation if pre_authorized

          if Catalog::RBAC::Role.catalog_administrator?
            relation
          else
            access_relation(relation)
          end
        end

        def access_relation(relation)
          access_obj = Insights::API::Common::RBAC::Access.new(relation.model.table_name, 'read').process
          raise Catalog::NotAuthorized, "Not Authorized for #{relation.model}" unless access_obj.accessible?
          if access_obj.owner_scoped?
            relation.by_owner
          else
            if relation.model.try(:supports_access_control?)
              ids = Catalog::RBAC::AccessControlEntries.new.ace_ids('read', relation.model)
              relation.where(:id => ids)
            else
              relation
            end
          end
        end

        def filtered(base_query)
          Insights::API::Common::Filter.new(base_query, params[:filter], api_doc_definition).apply
        end

        private

        def api_doc_definition
          @api_doc_definition ||= Api::Docs[api_version].definitions[model_name]
        end

        def api_version
          @api_version ||= name.split("::")[1].downcase.delete("v").sub("x", ".")
        end

        def model_name
          @model_name ||= controller_name.classify
        end

        def name
          self.class.to_s
        end
      end
    end
  end
end
