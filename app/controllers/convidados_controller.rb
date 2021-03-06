class ConvidadosController < ApplicationController
  before_filter :authenticate_user!
  def index
    @fiesta = Fiesta.friendly.find(params[:fiesta_id])
    @convidados = @fiesta.convidados
    @convidado = Convidado.new
    @convidado.fiesta_id = @fiesta.id
    authorize @convidados
  end

  def new
  end

  def show
  end

  def edit
  end

  def create
    @fiesta = Fiesta.friendly.find(params[:fiesta_id])
    @anfitrion = @fiesta.users.first
    @emails_txt = params[:convidado][:email]
    @emails = @emails_txt.split(/\s*,\s*/)
    @val = []
    @emails.each do |email|
      if email =~  /\A[\w+\-.]+@[a-z\d\-]+(?:\.[a-z\d\-]+)*\.[a-z]+\z/i
        @val << email
      end
    end
    @todo_ok = true
    @errores = []
    @val.each do |email|
      @convidado = @fiesta.convidados.find_or_create_by!(email: email) # Añadir un nuevo Convidado
      @convidado.anfitrion = @anfitrion # asignar anfitrion como el usuario actual
      authorize @convidado
      if @convidado.save
        if @convidado.invitado != nil
           ConvidadoMailer.delay.usuario_existente_convidado(@convidado)
           # @convidado.invitado.invitaciones.push(@convidado)
           # @convidado.invitado.fiestas.push(@convidado.fiesta)
        else
          # ConvidadoMailer.nuevo_usuario_convidado(@convidado, new_user_registration_url(:convidado_token => @convidado.token)).deliver #enviar la invitación a nuestro mailer para que entregue el mailer
          ConvidadoMailer.delay.nuevo_usuario_convidado(@convidado, new_user_registration_url) #enviar la invitación a nuestro mailer para que entregue el mailer
        end
        # redirect_to fiesta_convidados_path(@fiesta), notice: "Invitación enviada exitosamente."
      else
        @todo_ok = "false"
        @errores << @convidado.errors  
        # flash[:error] = "Hubo en error enviando la invitación. Intenta nuevamente"
        # redirect_to fiesta_convidados_path(@fiesta)
      end
    end
    if @todo_ok == "false"
      redirect_to fiesta_convidados_path(@fiesta)
       flash[:error] = "Hubo errores al crear los invitados. Intenta nuevamente"
    else
      redirect_to fiesta_convidados_path(@fiesta), notice: "#{@val.count.to_i} invitaciones enviadas exitosamente."
    end
  end

  def update
  end

  def destroy
    @fiesta = Fiesta.friendly.find(params[:fiesta_id])
    @convidado = Convidado.find(params[:id])
    if @convidado.destroy
      flash[:notice] = "Eliminado de la lista de convidados"
      redirect_to fiesta_convidados_path(@fiesta)
    else
      redirect_to fiesta_convidados_path(@fiesta)
      flash[:error] = "No se pudo eliminar. Intenta de nuevo."
    end
  end

  def confirmar
    @fiesta = Fiesta.friendly.find(params[:fiesta_id])
    @convidado = Convidado.find(params[:convidado_id])
    if @convidado.update_attribute(:asistencia, true)
    redirect_to :back, notice: "Tu asistencia ha sido confirmada."
    else
      redirect_to :back
      flash[:error] = "No pudimos confimar tu asistencia. Intenta nuevamente."
    end
  end

  def declinar
    @fiesta = Fiesta.friendly.find(params[:fiesta_id])
    @convidado = Convidado.find(params[:convidado_id])
    if @convidado.update_attribute(:asistencia, false)
    redirect_to :back, notice: "Tu asistencia ha sido declinada."
    else
      redirect_to :back
      flash[:error] = "No pudimos confimar tu asistencia. Intenta nuevamente."
    end
  end

  private
  def convidado_params
    params.require(:convidado).permit(:email, :asistencia)
  end
end
