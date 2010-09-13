module Neo4j

  # Handles events like a new node is created or deleted
  class EventHandler
    include org.neo4j.graphdb.event.TransactionEventHandler

    def initialize
      @listeners = []
      @filter_classes = []
    end


    def after_commit(data, state)
    end

    def after_rollback(data, state)
    end

    def before_commit(data)
      puts "before commit"
      print
      data.created_nodes.each{|node| node_created(node)}
      data.assigned_node_properties.each { |tx_data| property_changed(tx_data.entity, tx_data.key, tx_data.previously_commited_value, tx_data.value) }
      data.removed_node_properties.each { |tx_data| property_changed(tx_data.entity, tx_data.key, tx_data.previously_commited_value, tx_data.value) }
      data.deleted_nodes.each { |node| node_deleted(node)}
      # TODO Add relationship properties callbacks
    end

    def add(listener)
      puts "add #{listener.class}"
      @listeners << listener unless @listeners.include?(listener)
      add_filter(listener) # the listener do not want to get events on it self
    end

    def remove(listener)
      @listeners.delete(listener)
    end

    def remove_all
      @listeners = []
    end

    def print
      puts "Listeners #{@listeners.size}"
      @listeners.each {|li| puts "  Listener '#{li}'"}
    end

    def add_filter(filter_class)
      @filter_classes << filter_class  unless @filter_classes.include?(filter_class)
    end

    def remove_filter(filter_class)
      @filter_classes.delete filter_class
    end

    def node_created(node)
      return if @filter_classes.include?(node.class)
      @listeners.each {|li| li.on_node_created(node) if li.respond_to?(:on_node_created)}
    end

    def node_deleted(node)
      return if @filter_classes.include?(node.class)
      @listeners.each {|li| li.on_node_deleted(node) if li.respond_to?(:on_node_deleted)}
    end

    def relationship_created(relationship)
      return if @filter_classes.include?(relationship.class)
      @listeners.each {|li| li.on_relationship_created(relationship) if li.respond_to?(:on_relationship_created)}
    end

    def relationship_deleted(relationship)
      return if @filter_classes.include?(relationship.class)
      @listeners.each {|li| li.on_relationship_deleted(relationship) if li.respond_to?(:on_relationship_deleted)}
    end

    def property_changed(node, key, old_value, new_value)
      return if @filter_classes.include?(node.class)
      @listeners.each {|li| li.on_property_changed(node, key, old_value, new_value) if li.respond_to?(:on_property_changed)}
    end

    def tx_finished(tx)
      @listeners.each {|li| li.on_tx_finished(tx) if li.respond_to?(:on_tx_finished)}
    end

    def neo_started(neo_instance)
      @listeners.each {|li|  li.on_neo_started(neo_instance)  if li.respond_to?(:on_neo_started)}
    end

    def neo_stopped(neo_instance)
      @listeners.each {|li| li.on_neo_stopped(neo_instance) if li.respond_to?(:on_neo_stopped)}
    end
  end
end