class TimesheetsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :set_current_tab, :only => ['index']
  before_filter :find_timesheet, :only => ['edit', 'update']

  #----------------------------------------------------------------------------
  def index
    authorize! :read, Timesheet
    @timesheets = get_timesheets(:page => params[:page], :query => params[:query])

    respond_to do |format|
      format.html # index.html.haml
      format.js   # index.js.rjs
      format.xml  { render :xml => @timesheets }
    end
  end

  #----------------------------------------------------------------------------
  def new
    authorize! :create, Timesheet
    @timesheet = Timesheet.new(:user => current_user)

    respond_to do |format|
      format.html # new.html.haml
      format.js   # inew.js.rjs
      format.xml  { render :xml => @timesheet }
    end
  end

  #----------------------------------------------------------------------------
  def create
    @timesheet = Timesheet.new(params[:timesheet])
    if @timesheet.save
      redirect_to timesheets_path
      flash[:notice] = t(:msg_successfully_created, :value => t(:timesheet))
    else
      render :action => 'new'
      flash[:notice] = t(:msg_failed_to_create, :value => t(:timesheet))
    end
  end

  #----------------------------------------------------------------------------
  def edit
    respond_to do |format|
      format.html # new.html.haml
      format.js   # inew.js.rjs
      format.xml  { render :xml => @timesheet }
    end
  end

  #----------------------------------------------------------------------------
  def update
    if @timesheet.update_attributes(params[:timesheet])
      redirect_to timesheets_path
      flash[:notice] = t(:msg_successfully_updated, :value => t(:timesheet))
    else
      render :action => 'edit'
      flash[:notice] = t(:msg_failed_to_updated, :value => t(:timesheet))
    end

  end

  #----------------------------------------------------------------------------
  def search
    @timesheets = get_timesheets(:query => params[:query], :page => 1)

    respond_to do |format|
      format.js   { render :action => :index }
      format.xml  { render :xml => @timesheets.to_xml }
    end
  end

  #----------------------------------------------------------------------------
  def options
    @per_page = current_user.pref[:timesheets_per_page] || Timesheet.per_page
    @sort_by  = current_user.pref[:timesheets_sort_by]  || Timesheet.sort_by
    @send_recipients = current_user.pref[:timesheets_send_recipients] || Timesheet.recipient
    @cc_recipients = current_user.pref[:timesheets_cc_recipients] || Timesheet.recipient
  end

  #----------------------------------------------------------------------------
  def redraw
    current_user.pref[:timesheets_per_page] = params[:per_page] if params[:per_page]
    current_user.pref[:timesheets_sort_by]  = Timesheet::sort_by_map[params[:sort_by]] if params[:sort_by]
    current_user.pref[:timesheets_send_recipients]  = params[:send_recipients] if params[:send_recipients]
    current_user.pref[:timesheets_cc_recipients]  = params[:cc_recipients] if params[:cc_recipients]
    redirect_to timesheets_path
    flash[:notice] = t(:msg_successfully_updated, :value => t(:timesheet_options_small))
  end

  #----------------------------------------------------------------------------
  private
  #----------------------------------------------------------------------------
  def get_timesheets(options = { :page => nil, :query => nil })
    current_page = options[:page] if options[:page]
    current_query = options[:query] if options[:query]

    records = {
      :user => current_user,
      :order => current_user.pref[:timesheets_sort_by] || Timesheet.sort_by
    }
    pages = {
      :page => current_page,
      :per_page => current_user.pref[:timesheets_per_page]
    }

    # Call :get_timesheets hook and return its output if any.
    timesheets = hook(:get_timesheets, self, :records => records, :pages => pages)
    return timesheets.last unless timesheets.empty?

    # Default processing if no :get_timsheets hooks are present.
    if current_query.blank?
      Timesheet.my(records)
    else
      Timesheet.my(records).search(current_query)
    end.paginate(pages)
  end

  #----------------------------------------------------------------------------
  def find_timesheet
    @timesheet = Timesheet.find(params[:id])
  end

  #----------------------------------------------------------------------------
end