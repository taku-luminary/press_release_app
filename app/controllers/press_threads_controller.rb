class PressThreadsController < ApplicationController
  def index
    @press_threads = PressThread.all
    @gpts = Gpt.all
    @press_thread = PressThread.first
    @message = Message.new

    respond_to do |format|
      format.html
      format.json { 
        render json: {
          success: true,
          content: render_to_string(
            partial: 'content',
            locals: { press_thread: @press_thread, message: @message },
            formats: [:html]
          )
        }
      }
    end
  end

  def show
    @press_thread = PressThread.find(params[:id])
    @message = Message.new

    respond_to do |format|
      format.json { 
        render json: {
          success: true,
          content: render_to_string(
            partial: 'content',
            locals: { press_thread: @press_thread, message: @message },
            formats: [:html]
          )
        }
      }
    end
  end

  def new
    @press_thread = PressThread.new
    @press_threads = PressThread.all
    @gpts = Gpt.all

    respond_to do |format|
      format.html
      format.json { 
        render json: { 
          content: render_to_string(
            partial: 'press_threads/new_form',
            locals: { press_thread: @press_thread },
            formats: [:html]
          )
        }
      }
    end
  end

  def create
    @press_thread = PressThread.new(press_thread_params)

    respond_to do |format|
      if @press_thread.save
        format.json { 
          render json: { 
            success: true,
            thread: {
              id: @press_thread.id,
              title: @press_thread.title
            },
            content: render_to_string(
              partial: 'content',
              locals: { press_thread: @press_thread, message: Message.new },
              formats: [:html]
            )
          }
        }
      else
        format.json { 
          render json: { 
            success: false, 
            errors: @press_thread.errors.full_messages 
          }, status: :unprocessable_entity 
        }
      end
    end
  end

  def destroy
    @press_thread = PressThread.find(params[:id])
    @press_thread.destroy

    respond_to do |format|
      format.json { render json: { success: true } }
    end
  end

  private

  def press_thread_params
    params.require(:press_thread).permit(:title)
  end
end
