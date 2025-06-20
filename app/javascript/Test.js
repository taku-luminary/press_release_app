document.addEventListener('DOMContentLoaded', function() {


  // -------- グローバル関数 --------
  function deleteThread(threadId) {
    if (!confirm('このスレッドを削除してもよろしいですか？')) return;
  
    fetch(`/press_threads/${threadId}.json`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(async (r) => {
      // Railsのdestroyアクションが204(No Content)を返す場合に備えてハンドリング
      if (r.status === 204) return { success: true };
      try {
        return await r.json();
      } catch (_) {
        return { success: r.ok };
      }
    })
    .then(data => {
      if (data && data.success) {
        const item = document.querySelector(`.thread-item[data-thread-id="${threadId}"]`);
        if (item) item.remove();
  
        // 残っているスレッドを再表示
        const first = document.querySelector('.thread-item');
        if (first) {
          loadThread(first.dataset.threadId);
        } else {
          document.querySelector('.chat-main').innerHTML = `
            <div class="welcome-message">
              <h2>プレスリリース作成アシスタントへようこそ</h2>
              <p>左側の「新しいスレッド」ボタンをクリックして、新しいプレスリリースの作成を始めましょう。</p>
              <p>または、既存のスレッドを選択して続きから作業を再開できます。</p>
            </div>`;
        }
      } else {
        alert('削除に失敗しました');
      }
    })
    .catch(err => {
      console.error('Error:', err);
      alert('削除中にエラーが発生しました');
    });
  }
  
  // -------- DOMContentLoaded --------
  
  // document.addEventListener('DOMContentLoaded', function() {
    const gptSelect = document.getElementById('gpt-select');
    const currentGptNameSpan = document.getElementById('current-gpt-name');
    const currentThreadTitleSpan = document.getElementById('current-thread-title');
  
    // 初期表示の更新
    updateGptName();
    // updateThreadTitle(<%= @press_thread&.title.to_json || '""' %>);
  
    // GPT選択のイベントリスナー
    gptSelect.addEventListener('change', updateGptName);
  
    function updateGptName() {
      const selectedOption = gptSelect.options[gptSelect.selectedIndex];
      currentGptNameSpan.textContent = selectedOption ? selectedOption.text : 'N/A';
    }
  
    function updateThreadTitle(title) {
      currentThreadTitleSpan.textContent = title || '未選択';
    }
  
    // メッセージを最下部にスクロール
    function scrollToBottom() {
      const messages = document.querySelector('.messages');
      if (messages) {
        messages.scrollTop = messages.scrollHeight;
      }
    }
  
    // 初期表示時に最下部にスクロール
    scrollToBottom();
  
    // after scrollToBottom init add log
    console.log('event listeners initialized');
  
    // スレッド切り替え
    document.querySelectorAll('.thread-link').forEach(link => {
      link.addEventListener('click', function(e) {
        e.preventDefault();
        const threadId = this.dataset.threadId;
        loadThread(threadId);
      });
    });
  
    // スレッド読み込み
    function loadThread(threadId) {
      const threadLink = document.querySelector(`.thread-link[data-thread-id="${threadId}"]`);
      const threadTitle = threadLink ? threadLink.textContent : '未選択';
  
      fetch(`/press_threads/${threadId}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          document.getElementById('chat-content-wrapper').innerHTML = data.content;
          updateActiveThread(threadId);
          updateThreadTitle(threadTitle);
        }
      })
      .catch(error => console.error('Error:', error));
    }
  
    // アクティブなスレッドの更新
    function updateActiveThread(threadId) {
      document.querySelectorAll('.thread-item').forEach(item => {
        item.classList.remove('active');
        if (item.dataset.threadId === threadId) {
          item.classList.add('active');
        }
      });
    }
  
    // スレッド削除のイベントデリゲーション（inline onclick も OK）
    document.addEventListener('click', function(e) {
      const btn = e.target.closest('.delete-thread-btn');
      if (!btn) return;
      e.preventDefault();
      e.stopPropagation();
      deleteThread(btn.dataset.threadId);
    });
  
    // メッセージ送信フォームの処理
    document.addEventListener('submit', function(e) {
      if (e.target.classList.contains('message-form')) {
        e.preventDefault();
        const form = e.target;
        const formData = new FormData(form);
        const threadId = form.dataset.threadId;
  
        // フォームを無効化
        const textarea = form.querySelector('.message-textarea');
        const submitButton = form.querySelector('.send-button');
        textarea.disabled = true;
        submitButton.disabled = true;
  
        // ローディングメッセージを表示
        const loadingMessage = document.createElement('div');
        loadingMessage.className = 'loading-message';
        loadingMessage.innerHTML = `
          <div class="spinner"></div>
          <span>ChatGPTが応答を生成中です...</span>
        `;
        const messagesContainer = document.querySelector('.messages');
        messagesContainer.appendChild(loadingMessage);
        scrollToBottom();
  
        fetch(`/press_threads/${threadId}/messages`, {
          method: 'POST',
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            message: {
              content: formData.get('message[content]'),
              press_thread_id: threadId
            },
            company_name: document.getElementById('company_name').value,
            word_count: document.getElementById('word_count').value,
            target_audience: document.getElementById('target_audience').value,
            tone: document.getElementById('tone').value,
            required_words: document.getElementById('required_words').value,
            ng_words: document.getElementById('ng_words').value,
            main_message: document.getElementById('main_message').value,
            expected_action: document.getElementById('expected_action').value,
            expected_effect: document.getElementById('expected_effect').value
          })
        })
        .then(response => response.json())
        .then(data => {
          if (data.success) {
            document.querySelector('.chat-main').innerHTML = data.content;
            form.reset();
            scrollToBottom();
          } else {
            alert('メッセージの送信に失敗しました。');
          }
        })
        .catch(error => {
          console.error('Error:', error);
          alert('エラーが発生しました。');
        })
        .finally(() => {
          // ローディングメッセージを削除
          const loadingMessage = document.querySelector('.loading-message');
          if (loadingMessage) {
            loadingMessage.remove();
          }
          // フォームを再有効化
          textarea.disabled = false;
          submitButton.disabled = false;
          textarea.focus();
        });
      }
    });
  // });
  
  // GPTs作成モーダルの制御
  function showNewGptModal() {
    document.getElementById('newGptModal').style.display = 'block';
  }
  
  function closeNewGptModal() {
    document.getElementById('newGptModal').style.display = 'none';
  }
  
  // GPTs作成フォームの送信処理
  document.getElementById('newGptForm').addEventListener('submit', function(e) {
    e.preventDefault();
    const formData = new FormData(this);
  
    fetch('/gpts', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        gpt: {
          name: formData.get('gpt[name]'),
          description: formData.get('gpt[description]'),
          instructions: formData.get('gpt[instructions]')
        }
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // セレクトボックスに新しいGPTsを追加
        const select = document.getElementById('gpt-select');
        const option = new Option(data.gpt.name, data.gpt.id);
        select.add(option);
        select.value = data.gpt.id;
  
        // モーダルを閉じる
        closeNewGptModal();
        // フォームをリセット
        this.reset();
      } else {
        alert('GPTsの作成に失敗しました。');
      }
    })
    .catch(error => {
      console.error('Error:', error);
      alert('エラーが発生しました。');
    });
    console.log("OKOK");
  });
  
  // モーダル外クリックで閉じる
  window.onclick = function(event) {
    const newGptModal = document.getElementById('newGptModal');
    if (event.target == newGptModal) {
      closeNewGptModal();
    }
  }
    });