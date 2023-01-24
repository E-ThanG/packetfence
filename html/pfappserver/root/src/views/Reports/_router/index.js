import acl from '@/utils/acl'
import store from '@/store'
import TheIndex from '../'
import StoreModule from '../_store'
import BasesStoreModule from '@/views/Configuration/bases/_store'

const TheView = () => import(/* webpackChunkName: "Reports" */ '../_components/TheView')

const route = {
  path: '/reports',
  name: 'reports',
  redirect: `/reports/${encodeURIComponent('Accounting::Bandwidth')}`,
  component: TheIndex,
  meta: {
    can: () => acl.$some('read', ['reports']), // has ACL for 1+ children
    isFailRoute: true,
    transitionDelay: 300 * 2 // See _transitions.scss => $slide-bottom-duration
  },
  beforeEnter: (to, from, next) => {
    if (!store.state.$_reports) {
      // Register store module only once
      store.registerModule('$_reports', StoreModule)
      store.registerModule('$_bases', BasesStoreModule)
    }
    next()
  },
  children: [
    {
      path: ':id([a-zA-Z0-9]+.+[a-zA-Z0-9]+)/',
      name: 'report',
      component: TheView,
      props: route => ({ id: route.params.id }),
      meta: {
        can: 'read reports'
      }
    }
  ]
}

export default route
