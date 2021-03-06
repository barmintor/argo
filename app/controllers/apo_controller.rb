class ApoController < ApplicationController

  before_filter :create_obj, :except => [:register]
  after_filter :save_and_index, :only => [:delete_collection, :delete_collection, :add_collection, :update_title, :update_creative_commons, :update_use, :update_copyright, :update_default_object_rights, :add_roleplayer, :update_desc_metadata, :delete_role]

  
  def register
    param_cleanup params
    @cc= {
      'by' => 'Attribution 3.0 Unported',
      'by_sa' => 'Attribution Share Alike 3.0 Unported',
      'by-nd' => 'Attribution No Derivatives 3.0 Unported',
      'by-nc' => 'Attribution Non-Commercial 3.0 Unported', 
      'by-nc-sa' => 'Attribution Non-Commercial Share Alike 3.0 Unported',
      'by-nc-nd' => 'Attribution Non-commercial, No Derivatives 3.0 Unported', 
    }
    if params[:title]
      
      
      #register a new apo
      reg_params={}
      reg_params[:label] = params[:title]
      reg_params[:object_type] = 'adminPolicy'
      reg_params[:admin_policy] = 'druid:hv992ry2431'
      response = Dor::RegistrationService.create_from_request(reg_params)
      pid = response[:pid]
      item=Dor.find(pid)
      item.copyright_statement=params[:copyright]
      item.use_statement=params[:use]
      item.mods_title=params[:title]
      item.desc_metadata_format=params[:desc_md]
      item.metadata_source=params[:metadata_source]
      item.agreement=params[:agreement].to_s
      item.add_tag('Registered By : ' + current_user.login)
      if params[:collection] and params[:collection].length > 0
        item.add_default_collection params[:collection]
      end
      item.default_workflow=params[:workflow] unless(not params[:workflow] or params[:workflow].length<5)
      item.creative_commons_license = params[:cc_license]
      item.creative_commons_license_human=@cc[params[:cc_license]]
      item.default_rights = params[:default_object_rights]
      managers=params[:managers].split ' '
      viewers=params[:viewers].split ' '
      managers.each do |manager|
        if manager.include? 'sunetid'
          item.add_roleplayer 'dor-apo-manager', manager, 'person'
        else
          item.add_roleplayer 'dor-apo-manager', manager 
        end
      end
      viewers.each do |viewer|
         if viewer.include? 'sunetid'
           item.add_roleplayer 'dor-apo-viewer', viewer, 'person'
         else
           item.add_roleplayer 'dor-apo-viewer', viewer 
         end
       end
      item.save
      item.update_index
      respond_to do |format|
        format.any { redirect_to catalog_path(pid), :notice => 'APO created.' }
      end
      return
    end
    if params[:id]
      create_obj
      @managers=[]
      @viewers=[]
      if @object.roles['dor-apo-manager']
      
      @object.roles['dor-apo-manager'].each do |entity|
            @managers << entity.gsub('workgroup:', '').gsub('person:', '')
      end
    end
      if @object.roles['dor-apo-viewer']
      @object.roles['dor-apo-viewer'].each do |entity|
        @viewers << entity.gsub('workgroup:', '').gsub('person:', '')
      end
    end
    end
  end
  def param_cleanup params
    params[:title].strip! unless not params[:title]
    params[:managers]=params[:managers].gsub('\n',' ').gsub(',',' ') unless not params[:managers]
    params[:viewers]=params[:viewers].gsub('\n',' ').gsub(',',' ') unless not params[:viewers]
  end
  def update 
    @cc= {
      'by' => 'Attribution 3.0 Unported',
      'by_sa' => 'Attribution Share Alike 3.0 Unported',
      'by-nd' => 'Attribution No Derivatives 3.0 Unported',
      'by-nc' => 'Attribution Non-Commercial 3.0 Unported', 
      'by-nc-sa' => 'Attribution Non-Commercial Share Alike 3.0 Unported',
      'by-nc-nd' => 'Attribution Non-commercial, No Derivatives 3.0 Unported', 
    }
    @object.copyright_statement = params[:copyright]
    @object.use_statement = params[:use]
    @object.mods_title = params[:title]
    @object.desc_metadata_format = params[:desc_md]
    @object.metadata_source=params[:metadata_source]
    @object.agreement = params[:agreement].to_s
    if params[:collection] and params[:collection].length > 0
      @object.add_default_collection params[:collection]
    end
    @object.default_workflow=params[:workflow]
    @object.creative_commons_license = params[:cc_license]
    @object.creative_commons_license_human=@cc[params[:cc_license]]
    
    @object.default_rights = params[:default_object_rights]
    @object.purge_roles
    managers=params[:managers].split ' '
    viewers=params[:viewers].split ' '
    managers.each do |manager|
      if manager.include? 'sunetid'
        @object.add_roleplayer 'dor-apo-manager', manager, 'person'
      else
        @object.add_roleplayer 'dor-apo-manager', manager 
      end
    end
    viewers.each do |viewer|
       if viewer.include? 'sunetid'
         @object.add_roleplayer 'dor-apo-viewer', viewer, 'person'
       else
         @object.add_roleplayer 'dor-apo-viewer', viewer 
       end
     end
    save_and_index
    redirect
  end

  def add_roleplayer
    @object.add_roleplayer(params[:role], params[:roleplayer])
    redirect
  end

  def delete_role
    @object.delete_role(params[:role], params[:roleplayer])
    redirect
  end

  def delete_collection
    @object.remove_default_collection(params[:collection])
    redirect
  end

  def add_collection
    @object.add_default_collection(params[:collection])
    redirect
  end

  def update_title
    @object.mods_title = params[:title]
    redirect
  end

  def update_creative_commons
    @object.creative_commons = params[:creative_commons]
    redirect
  end

  def update_use
    @object.use_statement = params[:use]
    redirect
  end

  def update_copyright
    @object.copyright_statement = params[:copyright]
    redirect
  end

  def update_default_object_rights
    @object.default_rights = params[:rights]
    redirect
  end

  def update_desc_metadata
    @object.desc_metadata_format = params[:desc_metadata_format]
    redirect
  end


  private 
  def reindex item
    doc=item.to_solr
    Dor::SearchService.solr.add(doc, :add_attributes => {:commitWithin => 1000})
  end
  def create_obj
    if params[:id]
      @object = Dor.find params[:id], :lightweight => true
      @collections = @object.default_collections
      new_col=[]
      if @collections
        @collections.each do |col|
          new_col << Dor.find(col)
        end
      end
      @collections=new_col
    else
      raise 'missing druid'
    end
  end
  def save_and_reindex
    @object.save
    reindex @object
  end

  def save_and_index
    @object.save
    @object.update_index
  end

  def redirect
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'APO updated.' }
    end
  end

  #check that the user can carry out this item modification
  def forbid
    if not current_user.is_admin and not @object.can_manage_content?(current_user.roles params[:id])
      render :status=> :forbidden, :text =>'forbidden'
      return
    end
  end
end