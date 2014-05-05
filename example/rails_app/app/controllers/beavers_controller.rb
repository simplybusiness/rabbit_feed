class BeaversController < ApplicationController
  before_action :set_beaver, only: [:show, :edit, :update, :destroy]

  # GET /beavers
  # GET /beavers.json
  def index
    @beavers = Beaver.all
  end

  # GET /beavers/1
  # GET /beavers/1.json
  def show
  end

  # GET /beavers/new
  def new
    @beaver = Beaver.new
  end

  # GET /beavers/1/edit
  def edit
  end

  # POST /beavers
  # POST /beavers.json
  def create
    @beaver = Beaver.new(beaver_params)

    respond_to do |format|
      if @beaver.save
        publish_event 'user_creates_beaver'
        format.html { redirect_to @beaver, notice: 'Beaver was successfully created.' }
        format.json { render :show, status: :created, location: @beaver }
      else
        format.html { render :new }
        format.json { render json: @beaver.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /beavers/1
  # PATCH/PUT /beavers/1.json
  def update
    respond_to do |format|
      if @beaver.update(beaver_params)
        publish_event 'user_updates_beaver'
        format.html { redirect_to @beaver, notice: 'Beaver was successfully updated.' }
        format.json { render :show, status: :ok, location: @beaver }
      else
        format.html { render :edit }
        format.json { render json: @beaver.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /beavers/1
  # DELETE /beavers/1.json
  def destroy
    @beaver.destroy
    publish_event 'user_deletes_beaver'
    respond_to do |format|
      format.html { redirect_to beavers_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_beaver
      @beaver = Beaver.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def beaver_params
      params.require(:beaver).permit(:name)
    end

    def publish_event name
      RabbitFeed::Producer.publish_event name, { 'beaver_name' => @beaver.name }
    end
end
