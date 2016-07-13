class Api::VisualizationsController < ApiController

  before_action :set_visualization_and_dataset
  before_action :require_visualization_ownership!, except: [:show]

  def show
  end

  def update
    node_custom_fields     = params[:visualization][:node_custom_fields] || []
    relation_custom_fields = params[:visualization][:relation_custom_fields] || []
    @dataset.node_custom_fields     = node_custom_fields.map{ |cf| { "name" => cf["name"].downcase.gsub(' ', '_'), "type" => ["string", "number", "boolean"].any?{ |t| t == cf["type"].downcase } ? cf["type"].downcase : "string" } }
    @dataset.relation_custom_fields = relation_custom_fields.map{ |cf| { "name" => cf["name"].downcase.gsub(' ', '_'), "type" => ["string", "number", "boolean"].any?{ |t| t == cf["type"].downcase } ? cf["type"].downcase : "string" } }
    @dataset.save
    params[:visualization].except!(:node_custom_fields, :relation_custom_fields)
    @visualization.update(visualization_params)
    render :show
  end

  def network_analysis
    results, metrics_names = NetworkAnalysis.new(@dataset).calculate_metrics

    # Create the new custom fields, if needed
    # TODO: Refactor to avoid duplication with code above
    network_metrics = metrics_names.map do |metric_name|
      { "name" => metric_to_custom_field_name(metric_name), "type" => "number" }
    end
    @dataset.node_custom_fields = (@dataset.node_custom_fields + network_metrics).uniq
    @dataset.save!

    # Populate the custom fields with the generated values.
    # To make sure we delete potentially existing stale values, we don't iterate through the results,
    # we iterate through all the nodes, cleaning existing values as we go.
    @dataset.nodes.each do |node|
      node_metrics = results[node.id.to_s] || {}
      metrics_names.each do |metric_name|
        custom_field_name = metric_to_custom_field_name(metric_name)
        node.custom_fields[custom_field_name] = node_metrics[metric_name]
      end
      node.save!
    end
  end

  private

  def set_visualization_and_dataset
    @visualization = Visualization.find(params[:id])
    @dataset = @visualization.dataset
  end

  def require_visualization_ownership!
    render :show and return unless authorized
  end

  def authorized
    (@visualization.author == current_user) || (@visualization.author == demo_user)
  end

  def visualization_params
    params.require(:visualization).permit(:name, :description, :published, :author_id, :parameters)
  end

  # TODO: We're using the metric name as the custom field name, with an underscore prefix to avoid
  # crashing with potential user-generated fields. Should review/discuss this.
  def metric_to_custom_field_name(metric_name)
    '_'+metric_name
  end
end