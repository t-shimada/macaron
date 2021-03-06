require 'rails_helper'

RSpec.describe QuestionsController, :type => :controller do
  before(:each) do
    @logined_user = logined_by(mock_logined_user)
  end

  describe "GET index" do
    before(:each) do
      @questions = double
      expect(Question).to receive(:search_question)
        .with(hash_including('title' => 'タイトル1'))
        .and_return @questions

      get :index, title: 'タイトル1'
    end

    it { expect(response).to render_template(:index) }
    it { expect(assigns(:questions)).to eq @questions }
  end

  describe "GET show" do
    before(:each) do
      @question = mock_model(Question)
      @questions = []
      @answers = mock_model(Answer)
    end

    context '対象が指定されていないとき' do
      before(:each) do
        get :show, id: ''
      end

      it '質問一覧画面が表示されること' do
        expect(response).to redirect_to(questions_url)
      end

      it 'アラートが表示されること' do
        expect(flash[:alert]).to eq '対象が指定されていません'
      end
    end

    context '対象が存在しないとき' do
      before(:each) do
        allow(Question).to receive(:where).with(id: 0.to_s).and_return(@questions)
        expect(@questions).to receive(:first).and_return(nil)

        get :show, id: 0
      end

      it '質問一覧画面が表示されること' do
        expect(response).to redirect_to(questions_url)
      end

      it 'アラートが表示されること' do
        expect(flash[:alert]).to eq '対象が見つかりません'
      end
    end

    context '対象が存在するとき' do
      before(:each) do
        allow(Question).to receive(:where).with(id: @question.id.to_s).and_return(@questions)
        expect(@questions).to receive(:first).and_return(@question)

        get :show, id: @question.id
      end

      it '質問詳細画面が表示されること' do
        expect(response).to render_template(:show)
      end

      it { expect(assigns(:question)).to eq @question }
    end
  end

  describe "GET new" do
    before(:each) do
      @question = mock_model(Question)
      expect(Question).to receive(:new).and_return(@question)

      get :new
    end

    it '質問新規登録画面を呼び出すこと' do
      expect(response).to render_template(:new)
    end

    it '新規レコード用の@questionが設定されること' do
      expect(assigns(:question)).to be @question
    end
  end

  describe "POST create" do
    before(:each) do
      @question = mock_model(Question)

      allow(Question).to receive(:new).and_return(@question)
    end

    context '質問の登録に成功するとき' do
      before(:each) do
        expect(Question).to receive(:new).with(
          'title' => 'タイトル',
          'question' => '質問',
          'charge' => '担当者',
          'priority' => Question::PRIORITY[:mid].to_s,
          'limit_datetime' => 1.days.since.strftime('%Y%m%d'),
        ).and_return(@question)
        expect(@question).to receive(:created_user_name=).with(@logined_user.name)
        expect(@question).to receive(:updated_user_name=).with(@logined_user.name)
        expect(@question).to receive(:save!)

        post :create, question: {
          'title' => 'タイトル',
          'question' => '質問',
          'charge' => '担当者',
          'priority' => Question::PRIORITY[:mid].to_s,
          'limit_datetime' => 1.days.since.strftime('%Y%m%d'),
        }
      end

      it 'showにリダイレクトされること' do
        expect(response).to redirect_to(question_url(@question))
      end

      it '登録成功のメッセージが表示されること' do
        expect(flash[:notice]).to eq('質問を登録しました')
      end
    end

    context '質問の登録に失敗するとき' do
      before(:each) do
        expect(@question).to receive(:valid?).and_return false
        expect(@question).to receive(:created_user_name=).with(@logined_user.name)
        expect(@question).to receive(:updated_user_name=).with(@logined_user.name)

        post :create, question: { title: 'タイトル' }
      end

      it 'newを再描画すること' do
        expect(response).to render_template(:new)
      end
    end
  end

  describe "GET edit" do
    before(:each) do
      @question = mock_model(Question, id: 1)
      @questions = []
    end

    context '対象が指定されていないとき' do
      before(:each) do
        get :edit, id: ''
      end

      it '質問一覧画面が表示されること' do
        expect(response).to redirect_to(questions_url)
      end

      it 'アラートが表示されること' do
        expect(flash[:alert]).to eq '対象が指定されていません'
      end
    end

    context '対象が存在しないとき' do
      before(:each) do
        expect(Question).to receive(:where).with(id: 0.to_s).and_return(@questions)
        expect(@questions).to receive(:first).and_return(nil)

        get :edit, id: 0
      end

      it '質問一覧画面が表示されること' do
        expect(response).to redirect_to(questions_url)
      end

      it 'アラートが表示されること' do
        expect(flash[:alert]).to eq '対象が見つかりません'
      end
    end

    context '対象が存在するとき' do
      before(:each) do
        expect(Question).to receive(:where).with(id: @question.id.to_s).and_return(@questions)
        expect(@questions).to receive(:first).and_return(@question)

        get :edit, id: @question.id
      end

      it '質問編集画面が表示されること' do
        expect(response).to render_template(:edit)
      end

      it { expect(assigns(:question)).to eq @question }
    end
  end

  describe "PATCH update" do
    before(:each) do
      @question = mock_model(Question, id: 1)
    end

    context '成功するとき' do
      before(:each) do
        allow(Question).to receive_message_chain(:where, :first).and_return(@question)
        expect(@question).to receive(:update!)
          .with('title' => 'タイトル変更')
          expect(@question).to receive(:updated_user_name=).with(@logined_user.name)

        patch(:update, id: @question.id, question: {
          title: 'タイトル変更'
        })
      end

      it '質問詳細画面へ遷移すること' do
        expect(response).to redirect_to(question_url(@question))
      end

      it { expect(flash[:notice]).to eq '質問を更新しました' }
    end

    context '失敗するとき' do
      before(:each) do
        allow(Question).to receive_message_chain(:where, :first).and_return(@question)
        expect(@question).to receive(:update!)
          .with('title' => 'タイトル変更')
          .and_raise(ActiveRecord::RecordInvalid.new(@question))
        expect(@question).to receive(:updated_user_name=).with(@logined_user.name)

        patch(:update, id: @question.id, question: {
          title: 'タイトル変更'
        })
      end

      it '質問編集画面を再表示すること' do
        expect(response).to render_template(:edit)
      end

      it { expect(assigns(:question)).to eq @question }
    end

    context '対象が指定されていないとき' do
      before(:each) do

        patch(:update, id: '', question: {
          title: 'タイトル変更'
        })
      end

      it '質問一覧画面に遷移すること' do
        expect(response).to redirect_to(questions_url)
      end

      it { expect(flash[:alert]).to eq '対象が指定されていません' }
    end

    context '対象が存在しないとき' do
      before(:each) do
        allow(Question).to receive_message_chain(:where, :first).and_return(nil)

        patch(:update, id: '0', question: {
            title: 'タイトル変更'
        })
      end

      it '質問一覧画面に遷移すること' do
        expect(response).to redirect_to(questions_url)
      end

      it { expect(flash[:alert]).to eq '対象が見つかりません' }
    end
  end
  
  describe 'DELETE destroy' do
    before(:each) do
      @question = mock_model(Question, id: 1)
      @answer = mock_model(Answer)
      @answers = [@answer]
      @question_attachment = mock_model(QuestionAttachment)
      @answer_attachment = mock_model(AnswerAttachment)
    end

    context '成功するとき' do
      before(:each) do
        expect(Question).to receive(:find_by_id).and_return @question
        allow(@question).to receive(:answers).and_return @answers
        allow(@question).to receive(:question_attachment).and_return @question_attachment
        allow(@answer).to receive(:answer_attachment).and_return @answer_attachment
        expect(@answer).to receive(:destroy)
        expect(@question_attachment).to receive(:destroy)
        expect(@answer_attachment).to receive(:destroy)

        delete :destroy, id: @question.id
      end

      it '質問一覧画面にリダイレクトされること' do
        expect(response).to redirect_to(questions_url)
      end

      it '削除完了メッセージが表示されること' do
        expect(flash[:notice]).to eq('質問を削除しました')
      end
    end

    context '失敗するとき' do
      before(:each) do
        expect(Question).to receive(:find_by_id).and_return @question
        expect(@question).to receive(:destroy).and_raise

        delete :destroy, id: @question.id
      end

      it '質問一覧画面に遷移すること' do
        expect(response).to redirect_to(questions_url)
      end

      it { expect(flash[:alert]).to eq('質問の削除に失敗しました') }
    end
  end

  describe 'GET edit_status' do
    before(:each) do
      @question = mock_model(Question, id: 1)
      @questions = []
    end

    context '対象が指定されていないとき' do
      before(:each) do
        get :edit, id: ''
      end

      it '質問一覧画面が表示されること' do
        expect(response).to redirect_to(questions_url)
      end

      it 'アラートが表示されること' do
        expect(flash[:alert]).to eq '対象が指定されていません'
      end
    end

    context '対象が存在しないとき' do
      before(:each) do
        expect(Question).to receive(:where).with(id: 0.to_s).and_return(@questions)
        expect(@questions).to receive(:first).and_return(nil)

        get :edit, id: 0
      end

      it '質問一覧画面が表示されること' do
        expect(response).to redirect_to(questions_url)
      end

      it 'アラートが表示されること' do
        expect(flash[:alert]).to eq '対象が見つかりません'
      end
    end

    context '対象が存在するとき' do
      before(:each) do
        expect(Question).to receive(:where).with(id: @question.id.to_s).and_return(@questions)
        expect(@questions).to receive(:first).and_return(@question)

        get :edit, id: @question.id
      end

      it '質問編集画面が表示されること' do
        expect(response).to render_template(:edit)
      end

      it { expect(assigns(:question)).to eq @question }
    end
  end

  describe 'PATCH update_status' do
    before(:each) do
      @question = mock_model(Question, id: 1)
    end

    context '成功するとき' do
      before(:each) do
        allow(Question).to receive_message_chain(:where, :first).and_return(@question)
        expect(@question).to receive(:update!)
          .with('status' => Question::STATUS[:answered].to_s)
        expect(@question).to receive(:updated_user_name=).with(@logined_user.name)

        patch(:update_status, id: @question.id, question: {
          status: Question::STATUS[:answered].to_s,
        })
      end

      it '質問詳細画面へ遷移すること' do
        expect(response).to redirect_to(question_url(@question))
      end

      it { expect(flash[:notice]).to eq 'ステータスを更新しました' }
    end

    context '失敗するとき' do
      before(:each) do
        allow(Question).to receive_message_chain(:where, :first).and_return(@question)
        expect(@question).to receive(:update!)
          .with('status' => Question::STATUS[:answered].to_s)
          .and_raise(ActiveRecord::RecordInvalid.new(@question))
        expect(@question).to receive(:updated_user_name=).with(@logined_user.name)

        patch(:update_status, id: @question.id, question: {
          status: Question::STATUS[:answered]
        })
      end

      it '質問編集画面を再表示すること' do
        expect(response).to render_template(:edit)
      end

      it { expect(assigns(:question)).to eq @question }
    end

    context '対象が指定されていないとき' do
      before(:each) do

        patch(:update, id: '', question: {
          status: Question::STATUS[:answered]
        })
      end

      it '質問一覧画面に遷移すること' do
        expect(response).to redirect_to(questions_url)
      end

      it { expect(flash[:alert]).to eq '対象が指定されていません' }
    end

    context '対象が存在しないとき' do
      before(:each) do
        allow(Question).to receive_message_chain(:where, :first).and_return(nil)

        patch(:update, id: '0', question: {
            status: Question::STATUS[:answered]
        })
      end

      it '質問一覧画面に遷移すること' do
        expect(response).to redirect_to(questions_url)
      end

      it { expect(flash[:alert]).to eq '対象が見つかりません' }
    end
  end
end
