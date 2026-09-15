import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import AdminApp from './admin-app/AdminApp';
import './index.css';

function Root() {
  const urlParams = new URLSearchParams(window.location.search);
  const isAdminView = urlParams.get('app') === 'admin' || window.location.pathname === '/admin';

  if (isAdminView) {
    return <AdminApp />;
  }

  return <App />;
}

const rootElement = document.getElementById('root');
if (rootElement) {
  ReactDOM.createRoot(rootElement).render(
    <React.StrictMode>
      <Root />
    </React.StrictMode>
  );
}
