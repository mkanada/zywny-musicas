// Apagar a conta e os dados (LGPD / Google Play), sem Cloud Functions.
//
// Faz no navegador o mesmo que o app: `apagarDadosDaConta`, em
// zywny-aprendizado/lib/app/apagar_dados_da_conta.dart. Se as coleções do app
// mudarem, mude as duas listas. A ordem importa: primeiro o Firestore, depois o
// login (sem ele, as regras não deixam apagar mais nada).
import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-app.js';
import {
  getAuth, signInWithPopup, signOut, deleteUser,
  GoogleAuthProvider, GithubAuthProvider, OAuthProvider,
} from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-auth.js';
import {
  getFirestore, collection, query, where, getDocs, doc, deleteDoc,
  writeBatch,
} from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-firestore.js';

// Configuração web do projeto. A chave não é segredo: quem protege os dados são
// as regras do Firestore.
const config = {
  "apiKey": "AIzaSyB4zdv_Df0mFfDwA8VmhFUbHBdItWUoQsY",
  "authDomain": "zywny-aprendizagem-fb-proj.firebaseapp.com",
  "projectId": "zywny-aprendizagem-fb-proj",
  "storageBucket": "zywny-aprendizagem-fb-proj.firebasestorage.app",
  "messagingSenderId": "548163024718",
  "appId": "1:548163024718:android:4d93d2ba542b4677ae501f"
};

const app = initializeApp(config);
const auth = getAuth(app);
const db = getFirestore(app);

const provedores = {
  google: () => new GoogleAuthProvider(),
  microsoft: () => new OAuthProvider('microsoft.com'),
  github: () => new GithubAuthProvider(),
  apple: () => new OAuthProvider('apple.com'),
};

const $ = (id) => document.getElementById(id);
const tamanhoDoLote = 400;

function aviso(texto, erro = false) {
  const el = $('estado');
  el.textContent = texto;
  el.className = erro ? 'erro' : '';
}

async function apagarTodos(consulta) {
  const fotos = await getDocs(consulta);
  for (let i = 0; i < fotos.docs.length; i += tamanhoDoLote) {
    const lote = writeBatch(db);
    for (const d of fotos.docs.slice(i, i + tamanhoDoLote)) lote.delete(d.ref);
    await lote.commit();
  }
}

async function apagarDadosDaConta(uid) {
  // Do aluno.
  await apagarTodos(collection(db, `usuarios/${uid}/dias`));
  await apagarTodos(collection(db, `usuarios/${uid}/sessoes`));
  await apagarTodos(query(collection(db, 'convites'), where('alunoUid', '==', uid)));
  await apagarTodos(query(collection(db, 'vinculos'), where('alunoUid', '==', uid)));
  await deleteDoc(doc(db, `usuarios/${uid}/resumo/atual`));
  // Do responsável.
  await apagarTodos(collection(db, `responsaveis/${uid}/avisos`));
  await apagarTodos(query(collection(db, 'vinculos'), where('respUid', '==', uid)));
  await deleteDoc(doc(db, `responsaveis/${uid}`));
}

function mostrar(usuario) {
  $('entrar').hidden = !!usuario;
  $('confirmar').hidden = !usuario;
  if (usuario) {
    $('quem').textContent = usuario.email || usuario.displayName || usuario.uid;
  }
}

for (const botao of document.querySelectorAll('[data-provedor]')) {
  botao.addEventListener('click', async () => {
    aviso('Abrindo o login…');
    try {
      const r = await signInWithPopup(auth, provedores[botao.dataset.provedor]());
      aviso('');
      mostrar(r.user);
    } catch (e) {
      aviso(`Não consegui entrar: ${e.code || e.message}`, true);
    }
  });
}

$('cancelar').addEventListener('click', async () => {
  await signOut(auth);
  aviso('');
  mostrar(null);
});

$('apagar').addEventListener('click', async () => {
  const usuario = auth.currentUser;
  if (!usuario) return;
  $('apagar').disabled = true;
  aviso('Apagando…');
  try {
    await apagarDadosDaConta(usuario.uid);
    await deleteUser(usuario);
    $('confirmar').hidden = true;
    $('pronto').hidden = false;
    aviso('');
  } catch (e) {
    $('apagar').disabled = false;
    aviso(`Não consegui apagar: ${e.code || e.message}. Tente de novo ou escreva para zywny.app@gmail.com.`, true);
  }
});

$('ok').addEventListener('change', (e) => { $('apagar').disabled = !e.target.checked; });
mostrar(null);
