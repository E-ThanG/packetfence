import acl from '@/utils/acl'
import store from '@/store'
import StatusView from '../'
import StatusStore from '../_store'
import Dashboard from '../_components/Dashboard'
import Network from '../_components/Network'
import Services from '../_components/Services'
import Queue from '../_components/Queue'
import ClusterServices from '../_components/ClusterServices'

const route = {
  path: '/status',
  name: 'status',
  redirect: '/status/dashboard',
  component: StatusView,
  meta: {
    transitionDelay: 300 * 2 // See _transitions.scss => $slide-bottom-duration
  },
  beforeEnter: (to, from, next) => {
    if (!store.state.$_status) {
      // Register store module only once
      store.registerModule('$_status', StatusStore)
    }
    if (acl.$can('read', 'system'))
      store.dispatch('$_status/getCluster').then(() => next())
    else
      next()
  },
  children: [
    {
      path: 'dashboard',
      component: Dashboard,
      props: { storeName: '$_status' },
      beforeEnter: (to, from, next) => {
        if (acl.$can('read', 'users_sources'))
          store.dispatch('config/getSources')
        if (acl.$can('read', 'system')) {
          store.dispatch('$_status/getCluster').then(() => {
            store.dispatch('$_status/allCharts').finally(() => next())
          }).catch(() => next())
        }
      },
      meta: {
        can: 'read reports',
        fail: { path: '/auditing', replace: true }
      }
    },
    {
      path: 'network',
      name: 'statusNetwork',
      component: Network,
      props: (route) => ({ query: route.query.query }),
      meta: {
        can: 'read nodes',
        fail: { path: '/status/dashboard', replace: true }
      }
    },
    {
      path: 'services',
      component: Services,
      props: { storeName: '$_status' },
      meta: {
        can: 'read services',
        fail: { path: '/status/dashboard', replace: true }
      }
    },
    {
      path: 'queue',
      component: Queue,
      props: { storeName: 'pfqueue' },
      meta: {
        can: 'read services',
        fail: { path: '/status/dashboard', replace: true }
      }
    },
    {
      path: 'cluster/services',
      component: ClusterServices,
      props: { storeName: '$_status' },
      meta: {
        can: 'read services',
        fail: { path: '/status/dashboard', replace: true }
      }
    }
  ]
}

export default route
